
hexagon_area(dx, dy) = 3 * sqrt(3) * dx * dy / 2

hex_center(hex, r) = ArchGDAL.createpoint(Hexagons.center(hex, r, r, 0, 0))

function hexagonify(polys, hex_radius; buffer=0)
    all_geom = ArchGDAL.creategeomcollection()
    foreach(polys) do poly
        ArchGDAL.addgeom!(all_geom, poly)
    end
    hexagonify(ArchGDAL.convexhull(all_geom), hex_radius; buffer=buffer)
end

function hexagonify(g::AbstractGraph, hex_radius; buffer=0)
    all_points = ArchGDAL.createmultipoint()
    foreach(vertices(g)) do v
        ArchGDAL.addgeom!(all_points, get_prop(g, v, :pointgeom))
    end
    return hexagonify(ArchGDAL.convexhull(all_points), hex_radius; buffer=buffer)
end

function hexagonify(polygon::ArchGDAL.IGeometry, hex_radius; buffer=0, danger_value=10000)
    poly_bounding_box = ArchGDAL.boundingbox(polygon)
    expected_hexes = floor(Int, ArchGDAL.geomarea(polygon) / hexagon_area(hex_radius, hex_radius))
    @assert expected_hexes < danger_value "there are going to be about $expected_hexes in this cover. That is more than 1000"
    @info "hexagonification with about $expected_hexes expected hexes."

    start_hex = @chain polygon begin
        ArchGDAL.centroid
        getcoord
        collect
        cube_round(_..., hex_radius, hex_radius)
        neighbor(6)  # somehow, the offset is weird.
    end

    hexes = HexagonCubic[]
    i = 1
    while true
        ring_fully_outside_bbox = true
        for h in ring(start_hex, i)
            center = hex_center(h, hex_radius)
            if ArchGDAL.contains(polygon, center)
                push!(hexes, h)

            end
            ring_fully_outside_bbox &= !ArchGDAL.contains(poly_bounding_box, center)
        end
        if ring_fully_outside_bbox
            break
        end
        i += 1
    end

    # treat start hex separately, since ring(hex, 0) is empty...
    if ArchGDAL.contains(polygon, hex_center(start_hex, hex_radius))
        push!(hexes, start_hex)
    end
    return foldl(1:buffer, init=hexes) do hexes, _
        [hexes; hexgrid_buffer(hexes)]
    end
end

function hexgrid_buffer(hexes)
    buffered_hexes = HexagonCubic[]
    for h in hexes
        for n in Hexagons.neighbors(h)
            if !(n in hexes) && !(n in buffered_hexes)
                push!(buffered_hexes, n)
            end
        end
    end
    return buffered_hexes
end

function hexes2polys(hexes, hex_radius)
    map(hexes) do hex
        points = Hexagons.vertices(hex, hex_radius, hex_radius, 0, 0) |> collect .|> Tuple
        ArchGDAL.createpolygon([points; points[1]])
    end
end

function hexagon_histogram(aggregator, gdf::DataFrame, radius; buffer=0, filter_values=x -> true)

    project_local!(gdf.geometry, metadata(gdf, "center_lon"), metadata(gdf, "center_lat"))

    # setup hexagonal polygons
    hexes = hexes2polys(hexagonify(gdf.geometry, radius; buffer=buffer), radius)
    foreach(h -> reinterp_crs!(h, ArchGDAL.getspatialref(gdf.geometry[1])), hexes)
    hextree = build_rtree(hexes)

    values = zeros(length(hexes))
    for r in eachrow(gdf)
        values += aggregator(r, hextree)
    end

    project_back!(gdf.geometry)
    project_back!(hexes)
    values_filter = findall(filter_values, values)
    return hexes[values_filter], values[values_filter]
end

function hexagon_histogram(aggregator, iterator, g::AbstractGraph, radius; buffer=0, filter_values=x -> true)
    project_local!(g, get_prop(g, :center_lon), get_prop(g, :center_lat))
    # setup hexagonal polygons
    hexes = hexes2polys(hexagonify(g, radius; buffer=buffer), radius)
    foreach(h -> reinterp_crs!(h, get_prop(g, :crs)), hexes)
    hextree = build_rtree(hexes)

    values = zeros(length(hexes))
    for i in iterator
        values .+= aggregator(i, g, hextree)
    end

    project_back!(g)
    project_back!(hexes)
    values_filter = findall(filter_values, values)
    return hexes[values_filter], values[values_filter]
end