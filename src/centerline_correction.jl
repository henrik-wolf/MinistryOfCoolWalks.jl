norm(vec) = vec / sqrt(sum(vec.^2))

function offset_line(line, distance)
	points = [collect(getcoord(p)) for p in getgeom(line)]
	x = [i[1] for i in points]
	y = [i[2] for i in points]
	# TODO: figure out how to handle endpoints
	deltas = [norm([y[2]-y[1], -(x[2]-x[1])])]
	# for everything not endpoints, calculate offset direction and offset the points
	for i in 2:length(points)
		direction = [y[i]-y[i-1], -(x[i]-x[i-1])]
		push!(deltas, norm(direction))
	end
	push!(deltas, norm([y[end]-y[end-1], -(x[end]-x[end-1])]))
	directions = norm.(deltas[1:end-1] .+ deltas[2:end])
	
	new_line = ArchGDAL.createlinestring()
    for point in points + distance * directions
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
        intersecting_ids = Int[]
        # check for intersection with buildings.
        coarse_intersection = SpatialIndexing.intersects_with(building_tree, offset_linestring_rect)
        for spatialElement in coarse_intersection
            prep_geom = spatialElement.val.prep
            not_inter = !ArchGDAL.intersects(prep_geom, offset_linestring)
            not_inter && continue  # skip disjoint buildings
            push!(intersecting_ids, spatialElement.id)
            #@warn "edge $edge with osmid $(get_prop(g, edge, :osm_id)) intersect with a building."
        end
        return intersecting_ids
end

function correct_centerlines!(g, buildings)
    # project all stuff into local system
    center_lon = metadata(buildings, "center_lon")::Float64
    center_lat = metadata(buildings, "center_lat")::Float64

    project_local!(buildings.geometry, center_lon, center_lat)
    project_local!(g, center_lon, center_lat)

    offset_dir = get_prop(g, :offset_dir)
    building_tree = build_rtree(buildings.geometry)

    for edge in edges(g)
        !has_prop(g, edge, :edgegeom) && continue  # skip edges without geometry
        linestring = get_prop(g, edge, :edgegeom)
        id = get_prop(g, edge, :osm_id)

        # check if some buildings are intersecting from the start
        intersecting_building_before = check_building_intersection(building_tree, linestring)

        # the direction of the geometry of each edge should always point in the same direction as the edge (I believe I parse it that way)
        
        offset_dist = offset_dir * guess_offset_distance(g, edge)

        if abs(offset_dist) > 0
            offset_linestring = offset_line(linestring, offset_dist)
        else
            # just to check if the original line does not accidentaly touch a building.
            offset_linestring = linestring
        end

        intersection_buildings_after = check_building_intersection(building_tree, offset_linestring)
        if length(intersecting_building_before) < length(intersection_buildings_after)
            @warn "due to offsetting, some new intersections with buildings emerged in way $id, buildings: $intersection_buildings_after"
        end


        # TODO: if intersection: move back, else, ok
        set_prop!(g, edge, :edgegeom, offset_linestring)
    end
    #project all stuff back
    project_back!(buildings.geometry)
    project_back!(g)
    return nothing
end