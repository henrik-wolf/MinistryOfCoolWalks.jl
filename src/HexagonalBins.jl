"""
    hexagon_area(dx, dy)
    
area of a hexagon with radius 1, that is scaled by `dx` in x direction, and by `dy` in y direction.
"""
hexagon_area(dx, dy) = 3 * sqrt(3) * dx * dy / 2

"""
    hex_center(hex::Hexagons.Hexagon, r)
    
caculates the centerpoint of the `hex` with radius `r`. Returns an `ArchGDAL` point.
"""
hex_center(hex::Hexagons.Hexagon, r) = ArchGDAL.createpoint(Hexagons.center(hex, r, r, 0, 0))

"""
    hexagonify(geometries, hex_radius; kwargs...)
    hexagonify(df::DataFrame, hex_radius; kwargs...) = hexagonify(df.geometry, hex_radius; kwargs...)
    hexagonify(g::AbstractMetaGraph, hex_radius; kwargs...)
    hexagonify(polygon::ArchGDAL.IGeometry, hex_radius; buffer=0, danger_value=10000)

puts a bunch of hexagons with radius `hex_radius` in the area given by:
- the convex hull of a vector of `geometries`.
- the convex hull of the colum titled `:geometry` of a dataframe `df`.
- the convex hull of the `:sg_geometry` prop in the vertices of (`g`).
- a `polygon`.

All these things are expected to be ArchGDAL geometries.

A hexagon will be placed, if its centerpoint is within the polygon.

# keyword arguments
- `buffer`=0, number of times the resulting hex-grid should be buffered (that is, a layer of hexagons added to the outside) after filling the geometry.
- `danger_value=10000` if the approximated number of hexagons is larger than this value, we will throw an assertion error. This is to keep you from accidentally killing your REPL if you forget to convert between local and global corrdinate systems.

Returns a Vector of `Hexagons.HexagonCubic`s.
"""
function hexagonify(geometries, hex_radius; kwargs...)
    all_geom = ArchGDAL.creategeomcollection()
    foreach(geometries) do geom
        ArchGDAL.addgeom!(all_geom, geom)
    end
    hexagonify(ArchGDAL.convexhull(all_geom), hex_radius; kwargs...)
end

hexagonify(df::DataFrame, hex_radius; kwargs...) = hexagonify(df.geometry, hex_radius; kwargs...)

function hexagonify(g::AbstractMetaGraph, hex_radius; kwargs...)
    all_points = ArchGDAL.createmultipoint()
    foreach(vertices(g)) do v
        ArchGDAL.addgeom!(all_points, get_prop(g, v, :sg_geometry))
    end
    return hexagonify(ArchGDAL.convexhull(all_points), hex_radius; kwargs...)
end

function hexagonify(polygon::ArchGDAL.IGeometry, hex_radius; buffer=0, danger_value=10000)
    poly_bounding_box = ArchGDAL.boundingbox(polygon)
    expected_hexes = floor(Int, ArchGDAL.geomarea(polygon) / hexagon_area(hex_radius, hex_radius))
    @assert expected_hexes < danger_value "there are going to be about $expected_hexes in this cover. That is more than $danger_value"
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

"""
    hexgrid_buffer(hexes)

returns a vector of all hexagons that touch at least one hexagon in `hexes`, without duplicates.
"""
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


"""
    hexes2polys(hexes, hex_radius)

converts a vector of `Hexangons.Hexagon` with radius `hex_radius` to a vector of `ArchGDAL` polygons.
"""
function hexes2polys(hexes, hex_radius)
    map(hexes) do hex
        points = Hexagons.vertices(hex, hex_radius, hex_radius, 0, 0) |> collect .|> Tuple
        ArchGDAL.createpolygon([points; points[1]])
    end
end

"""
    get_crs_for_hexagons(df::DataFrame)
    get_crs_for_hexagons(g::AbstractMetaGraph) 

unified interface for accessing the local coordinate system of dataframes and graphs that support it.
"""
get_crs_for_hexagons(df::DataFrame) = ArchGDAL.getspatialref(df.geometry[1])
get_crs_for_hexagons(g::AbstractMetaGraph) = get_prop(g, :sg_crs)

"""
    hexagon_histogram(aggregator, geom_source, radius; buffer=0, danger_value=10000, filter_values=x -> true)

calculates the "generalised histogram" for data in a `DataFrame` or `MetaGraph`. For both these types, we expect
the following methods to be implemented:
- `project_local!`
- `build_rtree` (`val` should be a `NamedTuple` with at least the `ArchGDAL.IGeometry` under the keyword of `orig`).
- `hexagonify`
- `get_crs_for_hexagons`
- `project_back!`

# Arguments
- `aggregator`: closure `(actual_intersections::Vector{SpatialElem}, hexagon::ArchGDAL.IGemometry{WKBPolygon})->T`, where `T` is the type of result in each hexagon-bin.
    the first Argument is a Vector of the `SpatialElem`ents in the R-Tree of `geom_source`, where `ArchGDAL.intersects(hexagon, intersection.val.orig)==true`. The second
    argument is the hexagon which is currently aggregated over.
- `geom_source`: source of geometry for R-Tree (and maybe other data.), currently, `DataFrame` and `AbstractMetaGraph` are supported.
- `radius`: radius of hexagons in which the bins should be calculated. (Passed to `hexagonify`).

# Keyword Arguments
- `buffer=0`: Number of times the hexagons should be buffered before the aggregation.
- `danger_value=10000`: Number of predicted hexes above which `hexagonify` will fail.
- `filter_values=x->true`: Only hexagons where the `filter_values(aggregation_value)==true` will be returned.

# Process
We project `geom_source` to a local coordinate system and calculate the hexagonalisation of the area defined by it. The projected `geom_source`
is then converted into an `R-Tree`. For each hexagon in the hexagonalisation we calculate the value within that hexagon using the `aggregator`,
filter these `values` with `filter_values`, project everything back, and return only the hexagons and `values` where `filter_values(value)==true`.

Returns `(filtered_hexagons, filtered_values)`

# Examples
To get the number of nodes of a `ShadowGraph` in each hexagon with more than 0 nodes, you can do something like this:
```julia
hexes, values = hexagon_histogram(shadow_graph, 50; filter_values=(>(0))) inters, hex
    count(i -> i.val.type == :vertex, inters)
end
```

To get the total area of (possibly overlapping) buildings do:
```julia
hexes, values = hexagon_histogram(buildings, 50) do inters, hex
    geom = mapreduce(ArchGDAL.union, inters; init=ArchGDAL.createpolygon()) do i
        ArchGDAL.intersection(hex, i.val.orig)
    end
    return ArchGDAL.geomarea(geom)
end
```
"""
function hexagon_histogram(aggregator, geom_source, radius; buffer=0, danger_value=10000, filter_values=x -> true)
    project_local!(geom_source)
    source_rtree = build_rtree(geom_source)

    # setup hexagonal polygons
    hexes = hexagonify(geom_source, radius; buffer=buffer, danger_value=danger_value)
    poly_hexes = hexes2polys(hexes, radius)
    foreach(h -> reinterp_crs!(h, get_crs_for_hexagons(geom_source)), poly_hexes)
    prepared_poly_hexes = ArchGDAL.preparegeom.(poly_hexes)

    values = map(poly_hexes, prepared_poly_hexes) do hex, prep_hex
        possible_intersections = intersects_with(source_rtree, rect_from_geom(hex))
        actual_intersections = [i for i in possible_intersections if ArchGDAL.intersects(prep_hex, i.val.orig)]
        return aggregator(actual_intersections, hex)
    end

    project_back!(geom_source)
    project_back!(poly_hexes)
    values_filter = findall(filter_values, values)
    return poly_hexes[values_filter], values[values_filter]
end