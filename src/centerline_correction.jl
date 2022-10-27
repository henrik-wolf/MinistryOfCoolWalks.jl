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

#TODO: make this more cleverer
function guess_offset_distance(edge_tags)
    return 2
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

        offset_dist = offset_dir * guess_offset_distance(get_prop(g, edge, :tags))

        if offset_dist > 0
            offset_linestring = offset_line(linestring, offset_dist)
        else
            # just to check if the original line does not accidentaly touch a building.
            offset_linestring = linestring
        end

        offset_linestring_rect = rect_from_geom(offset_linestring)

        # check for intersection with buildings.
        coarse_intersection = SpatialIndexing.intersects_with(building_tree, offset_linestring_rect)
        for spatialElement in coarse_intersection
            prep_geom = spatialElement.val.prep
            not_inter = !ArchGDAL.intersects(prep_geom, offset_linestring)
            not_inter && continue  # skip disjoint buildings
            @warn "edge $edge with osmid $(get_prop(g, edge, :osm_id)) intersect with a building."
        end
        # TODO: if intersection: move back, else, ok
        set_prop!(g, edge, :edgegeom, offset_linestring)
    end
    #project all stuff back
    project_back!(buildings.geometry)
    project_back!(g)
    return nothing
end