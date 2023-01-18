"""

    node_directions(x, y)

calculates the (scaled) direction in which the nodes given by 'x' and 'y' coordinates need to be offset, such that the connections between the nodes remain
parallel to the original connections. Returns array of 2d vectors.
"""
function node_directions(x, y)
	# TODO: figure out how to handle endpoints
    # TODO: figure out if we need to detect intersections and trim of resulting loops...
	deltas = [unit([y[2]-y[1], -(x[2]-x[1])])]
	# for everything not endpoints, calculate offset direction of edge
	for i in 2:length(x)
		direction = unit([y[i]-y[i-1], -(x[i]-x[i-1])])
		push!(deltas, direction)
	end
	push!(deltas, unit([y[end]-y[end-1], -(x[end]-x[end-1])]))

    # check if endpoints of line are very close together (form a ring.) if so, make sure endpoints end up at the same location
    distance_start_end = sqrt((x[1] - x[end])^2 + (y[1]-y[end])^2)
    if distance_start_end < 1e-4
        deltas = [[deltas[end]]; deltas[2:end-1]; [deltas[1]]]
    end

	node_directions = unit.(deltas[1:end-1] .+ deltas[2:end])
    scalar_products = [node_dir' * edge_dir for (node_dir, edge_dir) in zip(node_directions, deltas)]
    node_directions ./= scalar_products
	return node_directions
end


"""
    offset_line(line, distance)

creates new `ArchGDAL` linestring where all segments are offset parallel to the original segment of `line`, with a distance of `distance`.
Looking down the line (from the first segment to the second...), a positive distance moves the line to the right, a negative distance to the left.
The line is expected to be in a projected coordinate system, which is going to be applied to the new, offset line as well.
If, continious offsetting the length of a line segment where to reach a length of 0, the two adjacent points are automatically merged and offsetting
is continued using the new configuration.
"""
function offset_line(line, distance)
	points = [collect(getcoord(p)) for p in getgeom(line)]
	x = [i[1] for i in points]
	y = [i[2] for i in points]
	
	node_dirs = node_directions(x, y)

	dx = x[2:end] .- x[1:end-1]
	dd = node_dirs[1:end-1] .- node_dirs[2:end]
	max_offsets = dx ./ [i[1] for i in dd]
	oks = map(maxo->sign(distance) != sign(maxo) || abs(distance) < abs(maxo), max_offsets)
	if reduce(&, oks)
		new_line = ArchGDAL.createlinestring()
	    for point in points + distance * node_dirs
	        ArchGDAL.addpoint!(new_line, point...)
	    end
	    reinterp_crs!(new_line, ArchGDAL.getspatialref(line))
	    return new_line
	else
		# signs are the same for distance and not ok offsets
		closest_index = findmin(abs, max_offsets)[2]
		closest_value = max_offsets[closest_index]
		distance_remaining = distance - closest_value
		popat!(points, closest_index)
		popat!(node_dirs, closest_index)

		new_line = ArchGDAL.createlinestring()
	    for point in points + closest_value * node_dirs
	        ArchGDAL.addpoint!(new_line, point...)
	    end
	    reinterp_crs!(new_line, ArchGDAL.getspatialref(line))
	    return offset_line(new_line, distance_remaining)
	end
end

#TODO: make this more clevererererer
""""

    guess_offset_distance(g, edge::Edge, assumed_lane_width=3.5)

estimates the the distance an `edge` of graph `g` has to be offset. Uses the `props` of the edge, the `assumed_lane_width`,
used as a fallback in case the information can not be found solely in the `props`, as well as the global constants of
`DEFAULT_LANES_ONEWAY`, `HIGHWAYS_OFFSET` and `HIGHWAYS_NOT_OFFSET`. This function calls:

    guess_offset_distance(edge_tags, parsing_direction, assumed_lane_width=3.5)

estimates the distance the edge with the tags `edge_tags`, which has been parse in the direction of `parsing_direction`.
(That is, if we had to go forwards or backwards through the OSM way in order to generate the edgeometry for this linestring.
This is nessecary, due to the existence of the reverseway tags and possible asymetries, where streets have more lanes in one direction,
than in the other.)
"""
function guess_offset_distance(g, edge::Edge, assumed_lane_width=3.5)
    edge_tags = get_prop(g, edge, :tags)
    direction = get_prop(g, edge, :parsing_direction)
    return guess_offset_distance(edge_tags, direction, assumed_lane_width)
end

function guess_offset_distance(edge_tags, parsing_direction, assumed_lane_width=3.5)
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
                return assumed_lane_width * lanes_parsing_direction/2
            end

            # otherwise, get number of lanes
            if !ismissing(lanes)
                if lanes == 0
                    id = get_prop(g, edge, :osm_id)
                    @warn "the number of lanes on way $id is 0."
                end
                return assumed_lane_width * lanes/2
            end

            #else return default number of lanes times default width for given waytype
            return assumed_lane_width * DEFAULT_LANES_ONEWAY[waytype]/2
        else
            # reconstruct the fraction at which the center is from forward, backward and bothway lanes
            if !ismissing(lanes_forward) && !ismissing(lanes_backward)
                combined_lanes = lanes_forward + lanes_backward + lanes_both_way
                lanes_parsing_direction = parsing_direction >= 0 ? lanes_forward : lanes_backward
                fraction = (lanes_parsing_direction + lanes_both_way/2) / combined_lanes

                if !ismissing(width)
                    return fraction * width
                else
                    return assumed_lane_width * fraction * combined_lanes
                end
            end

            if !ismissing(width)
                return width / 2
            end
            if !ismissing(lanes)
                return assumed_lane_width * lanes/2
            end

            return assumed_lane_width * DEFAULT_LANES_ONEWAY[waytype]
        end
    else
        @info "new waytype encountered: $waytype. You may want to choose wether or not to offset this one. (default is no offset)"
        return 0.0
    end
end

"""
    check_building_intersection(building_tree, offset_linestring)

checks if the linestring `offset_linestring` interescts with any of the buildings saved in the `building_tree`,
which is assumend to be an `RTree` of the same structure as generated by `build_rtree`. Returns the offending geometry,
or an empty list, if there are no intersections.
"""
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

"""

    correct_centerlines!(g, buildings, assumed_lane_width=3.5)

offsets the centerlines of streets (edges in `g`) stored in the edge prop `:edgegeom`, to the estimated edge of the street, using
information available in the edgeprops `:tags` and `parsing_direction`. If it is not possible to find the offset using these `props`,
the `assumed_lane_width` is used in conjunction with the gloabal dicts `DEFAULT_LANES_ONEWAY`, `HIGHWAYS_OFFSET` and `HIGHWAYS_NOT_OFFSET`,
to figure out, how far the edge should be offset. This guess is then multiplied by the `scale_factor`, to get the final distance by wich we
then offset the line.

If the highway is in `HIGHWAYS_NOT_OFFSET`, it is not going to be moved, no matter the contents of its `tags`. For the full reasoning and
implementations see the source of `guess_offset_distance`.

We check if the offset line does intersect more buildings than the original line, to make sure that the assumend foot/bike path does lead through
a building. If there have new intersections arrisen, we retry the offsetting with `0.9, 0.8, 0.7...` times the guessed offset, while checking and,
if true breaking, whether the additional intersections vanish.

We also update the locations of the helper nodes, to reflect the offset lines, as well as the ":full_length" prop, to reflect the possible change in length.
"""
function correct_centerlines!(g, buildings, assumed_lane_width=3.5, scale_factor=1.0)
    # project all stuff into local system
    center_lon = metadata(buildings, "center_lon")::Float64
    center_lat = metadata(buildings, "center_lat")::Float64

    project_local!(buildings.geometry, center_lon, center_lat)
    project_local!(g, center_lon, center_lat)

    offset_dir = get_prop(g, :offset_dir)
    building_tree = build_rtree(buildings.geometry)

    nodes_to_set_coords = []

    @showprogress 1 "correcting centerlines" for edge in edges(g)
        !has_prop(g, edge, :edgegeom) && continue  # skip edges without geometry
        linestring = get_prop(g, edge, :edgegeom)

        # check if some buildings are intersecting from the start
        intersecting_buildings_before = check_building_intersection(building_tree, linestring)

        # the direction of the geometry of each edge should always point in the same direction as the edge (I believe I parse it that way)
        
        offset_dist = offset_dir * guess_offset_distance(g, edge, assumed_lane_width) * scale_factor

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

            # update helper locations
            if get_prop(g, src(edge), :helper) && !get_prop(g, dst(edge), :helper)
                # if only the source is helper (multi edge)
                p = ArchGDAL.pointalongline(offset_linestring, 0.5 * ArchGDAL.geomlength(offset_linestring))
                set_prop!(g, src(edge), :pointgeom, p)
                push!(nodes_to_set_coords, src(edge))
            elseif get_prop(g, dst(edge), :helper) && !get_prop(g, src(edge), :helper)
                # if only the destination is helper (multi edge)
                p = ArchGDAL.pointalongline(offset_linestring, 0.5 * ArchGDAL.geomlength(offset_linestring))
                set_prop!(g, dst(edge), :pointgeom, p)
                push!(nodes_to_set_coords, dst(edge))
            elseif get_prop(g, src(edge), :helper) && get_prop(g, dst(edge), :helper)
                # if both, the source and destination are helpers ((multi-) self edges)
                p1 = ArchGDAL.pointalongline(offset_linestring, 0.1 * ArchGDAL.geomlength(offset_linestring))
                set_prop!(g, src(edge), :pointgeom, p1)
                push!(nodes_to_set_coords, src(edge))

                p2 = ArchGDAL.pointalongline(offset_linestring, 0.6 * ArchGDAL.geomlength(offset_linestring))
                set_prop!(g, dst(edge), :pointgeom, p2)
                push!(nodes_to_set_coords, dst(edge))
            end
            set_prop!(g, edge, :full_length, ArchGDAL.geomlength(offset_linestring))
        end
    end
    
    #project all stuff back
    project_back!(buildings.geometry)
    project_back!(g)

    for vertex in nodes_to_set_coords
        p = get_prop(g, vertex, :pointgeom)
        set_prop!(g, vertex, :lon, ArchGDAL.getx(p, 0))
        set_prop!(g, vertex, :lat, ArchGDAL.gety(p, 0))
    end

    return nothing
end