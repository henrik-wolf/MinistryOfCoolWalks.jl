norm(vec) = vec / sqrt(sum(vec.^2))

function offset_line(line, distance)
	points = [collect(getcoord(p)) for p in getgeom(line)]
	x = [i[1] for i in points]
	y = [i[2] for i in points]
	# TODO: figure out how to handle endpoints
	deltas = [norm([y[2]-y[1], -(x[2]-x[1])])]
	# for everything not endpoints, calculate offset direction of edge
	for i in 2:length(points)
		direction = norm([y[i]-y[i-1], -(x[i]-x[i-1])])
		push!(deltas, direction)
	end
	push!(deltas, norm([y[end]-y[end-1], -(x[end]-x[end-1])]))
	node_directions = norm.(deltas[1:end-1] .+ deltas[2:end])
    scalar_products = [node_dir' * edge_dir for (node_dir, edge_dir) in zip(node_directions, deltas)]
    node_directions ./= scalar_products
	
	new_line = ArchGDAL.createlinestring()
    for point in points + distance * node_directions
        ArchGDAL.addpoint!(new_line, point...)
    end
    reinterp_crs!(new_line, ArchGDAL.getspatialref(line))
    return new_line
end

#TODO: make this more clevererererer
function guess_offset_distance(g, edge::Edge)
    edge_tags = get_prop(g, edge, :tags)
    direction = get_prop(g, edge, :parsing_direction)
    return guess_offset_distance(edge_tags, direction)
end

function guess_offset_distance(edge_tags, parsing_direction)
    waytype = get(edge_tags, "highway", "default")
    if waytype in HIGHWAYS_NOT_OFFSET
        return 0.0
    elseif waytype in HIGHWAYS_OFFSET
        width = get(edge_tags, "width", missing)
        
        lanes = get(edge_tags, "lanes", missing)
        lanes_forward = get(edge_tags, "lanes:forward", missing)
        lanes_backward = get(edge_tags, "lanes:backward", missing)
        lanes_both_way = get(edge_tags, "lanes:both_ways", missing)
        lanes_both_way = ismissing(lanes_both_way) ? 0 : lanes_both_way

        oneway = edge_tags["oneway"]
        if oneway
            # start with width. If width is mapped, return half of that, since the mapped line is in the center
            if !ismissing(width)
                return width / 2
            end

            # otherwise, get the number of lanes in the direction of parsing
            lanes_parsing_direction = parsing_direction >= 0 ? lanes_forward : lanes_backward
            if !ismissing(lanes_parsing_direction)
                if lanes_parsing_direction == 0
                    id = get_prop(g, edge, :osm_id)
                    @warn "the number of lanes on way $id in parsing direction is $lanes_parsing_direction. forward: $lanes_forward, backward: $backward, both_ways: $both_ways"
                end
                return DEFAULT_LANE_WIDTH * lanes_parsing_direction/2
            end

            # otherwise, get number of lanes
            if !ismissing(lanes)
                if lanes == 0
                    id = get_prop(g, edge, :osm_id)
                    @warn "the number of lanes on way $id is 0."
                end
                return DEFAULT_LANE_WIDTH * lanes/2
            end

            #else return default number of lanes times default width for given waytype
            return DEFAULT_LANE_WIDTH * DEFAULT_LANES_ONEWAY[waytype]/2
        else
            # reconstruct the fraction at which the center is from forward, backward and bothway lanes
            if !ismissing(lanes_forward) && !ismissing(lanes_backward)
                combined_lanes = lanes_forward + lanes_backward + lanes_both_way
                lanes_parsing_direction = parsing_direction >= 0 ? lanes_forward : lanes_backward
                fraction = (lanes_parsing_direction + lanes_both_way/2) / combined_lanes

                if !ismissing(width)
                    return fraction * width
                else
                    return DEFAULT_LANE_WIDTH * fraction * combined_lanes
                end
            end

            if !ismissing(width)
                return width / 2
            end
            if !ismissing(lanes)
                return DEFAULT_LANE_WIDTH * lanes/2
            end

            return DEFAULT_LANE_WIDTH * DEFAULT_LANES_ONEWAY[waytype]
        end
    else
        @info "new waytype encountered: $waytype. You may want to choose wether or not to offset this one. (default is no offset)"
        return 0.0
    end
end

function check_building_intersection(building_tree, offset_linestring)
        offset_linestring_rect = rect_from_geom(offset_linestring)
        intersecting_geom = []
        # check for intersection with buildings.
        coarse_intersection = SpatialIndexing.intersects_with(building_tree, offset_linestring_rect)
        for spatialElement in coarse_intersection
            prep_geom = spatialElement.val.prep
            not_inter = !ArchGDAL.intersects(prep_geom, offset_linestring)
            not_inter && continue  # skip disjoint buildings
            push!(intersecting_geom, spatialElement.val.orig)
            #@warn "edge $edge with osmid $(get_prop(g, edge, :osm_id)) intersect with a building."
        end
        return intersecting_geom
end

function correct_centerlines!(g, buildings)
    # project all stuff into local system
    center_lon = metadata(buildings, "center_lon")::Float64
    center_lat = metadata(buildings, "center_lat")::Float64

    project_local!(buildings.geometry, center_lon, center_lat)
    project_local!(g, center_lon, center_lat)

    offset_dir = get_prop(g, :offset_dir)
    building_tree = build_rtree(buildings.geometry)

    @showprogress 1 "correcting centerlines" for edge in edges(g)
        !has_prop(g, edge, :edgegeom) && continue  # skip edges without geometry
        linestring = get_prop(g, edge, :edgegeom)

        # check if some buildings are intersecting from the start
        intersecting_buildings_before = check_building_intersection(building_tree, linestring)

        # the direction of the geometry of each edge should always point in the same direction as the edge (I believe I parse it that way)
        
        offset_dist = offset_dir * guess_offset_distance(g, edge)

        if abs(offset_dist) > 0
            offset_linestring = offset_line(linestring, offset_dist)

            # check for new intersections and move line back, until they are gone
            intersecting_buildings_after = check_building_intersection(building_tree, offset_linestring)
            if length(intersecting_buildings_before) < length(intersecting_buildings_after)
                distance_factor = 0.9
                min_dist = minimum(filter(x->x>1e-8, [ArchGDAL.distance(linestring, building) for building in intersecting_buildings_after]))
                while distance_factor >= 0 && length(intersecting_buildings_before) < length(intersecting_buildings_after)
                    offset_dist = offset_dir * min_dist * distance_factor
                    offset_linestring = offset_line(linestring, offset_dist)
                    intersecting_buildings_after = check_building_intersection(building_tree, offset_linestring)
                    distance_factor -= 0.1
                end
            end

            set_prop!(g, edge, :edgegeom, offset_linestring)
        end
    end
    #project all stuff back
    project_back!(buildings.geometry)
    project_back!(g)
    return nothing
end