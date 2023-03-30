hexagon_area(dx, dy) = 3 * sqrt(3) * dx * dy / 2

hex_center(hex, r) = ArchGDAL.createpoint(Hexagons.center(hex, r, r, 0, 0))

function hexagonify(g, hex_radius; buffer=0)
    all_points = ArchGDAL.createmultipoint()
    foreach(vertices(g)) do v
        ArchGDAL.addgeom!(all_points, get_prop(g, v, :pointgeom))
    end
    return hexagonify(ArchGDAL.convexhull(all_points), hex_radius; buffer=buffer)
end

function hexagonify(polygon::ArchGDAL.IGeometry, hex_radius; buffer=0)
    poly_bounding_box = ArchGDAL.boundingbox(polygon)

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
            @info "broke at ring $i"
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