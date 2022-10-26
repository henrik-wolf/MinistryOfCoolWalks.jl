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

function correct_centerlines!(g, buildings)
    # project all stuff into local system
    center_lon = metadata(buildings, "center_lon")::Float64
    center_lat = metadata(buildings, "center_lat")::Float64

    project_local!(buildings.geometry, center_lon, center_lat)
    project_local!(g, center_lon, center_lat)

    # TODO: figure out rotational direction of network

    building_tree = build_rtree(buildings.geometry)

    for edge in edges(g)
        !has_prop(g, edge, :edgegeom) && continue  # skip helpers
        linestring = get_prop(g, edge, :edgegeom)

        # TODO: estimate offset width of edge
        offset_dist = 4
        # TODO: offset edge
        offset_linestring = offset_line(linestring, offset_dist)
        offset_linestring_rect = rect_from_geom(offset_linestring)
        # TODO: check for overlap with building polygons something something R-Tree)
        coarse_intersection = SpatialIndexing.intersects_with(building_tree, offset_linestring_rect)
        for spatialElement in coarse_intersection
            prep_geom = spatialElement.val.prep
            not_inter = !ArchGDAL.intersects(prep_geom, offset_linestring)
            not_inter && continue  # skip disjoint buildings
            @warn "edge $edge with osmid $(get_prop(g, edge, :osm_id)) has been moved into a building."
        end
        # TODO: if intersection: move back, else, ok
        # TODO: set new edgegeom\
        set_prop!(g, edge, :edgegeom, offset_linestring)
    end
    #project all stuff back
    project_back!(buildings.geometry)
    project_back!(g)
    return nothing
end