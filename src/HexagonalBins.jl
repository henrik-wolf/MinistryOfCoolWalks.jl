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
    hexagonify(g::AbstractGraph, hex_radius; kwargs...)
    hexagonify(polygon::ArchGDAL.IGeometry, hex_radius; buffer=0, danger_value=10000)

puts a bunch of hexagons with radius `hex_radius` in the area given by:
- the convex hull of a vector of `geometries`.
- the convex hull of the `:pointgeom` prop in the vertices of (`g`).
- a `polygon`.

All these things are expected to be ArchGDAL geometries.

A hexagon will be placed, if its centerpoint is within the polygon.

# keyword arguments
- `buffer`=0, number of times the resulting hex-grid should be buffered (that is, a layer of hexagons added to the outside) after filling the geometry.
- `danger_value`=10000 if the approximated number of hexagons is larger than this value, we will throw an assertion error. This is to keep you from accidentally killing your repl if you forget to convert between local and global corrdinate systems.

Returns a Vector of `Hexagons.HexagonCubic`s.
"""
function hexagonify(geometries, hex_radius; kwargs...)
    all_geom = ArchGDAL.creategeomcollection()
    foreach(geometries) do geom
        ArchGDAL.addgeom!(all_geom, geom)
    end
    hexagonify(ArchGDAL.convexhull(all_geom), hex_radius; kwargs...)
end

function hexagonify(g::AbstractGraph, hex_radius; kwargs...)
    all_points = ArchGDAL.createmultipoint()
    foreach(vertices(g)) do v
        ArchGDAL.addgeom!(all_points, get_prop(g, v, :pointgeom))
    end
    return hexagonify(ArchGDAL.convexhull(all_points), hex_radius; kwargs...)
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

    hexagon_histogram(aggregator, gdf::DataFrame, radius; buffer=0, danger_value=10000, filter_values=x -> true)

calculates the "generalised histogram" for data in a dataframe `gdf`, which is expected to have the `"center_lon"`
and `"center_lat"` metadata, as well as a column named `:geometry`, which will be projected to local coordinates for
this function.
    
After projecting the we calculate the appropriate hexagon cover with hexagons of radius `radius`. The keywordarguments of
`buffer` and `danger_value` are passed to the `hexagonify` function accordingly.

We then build an rtree out of the resulting hexagonal geometries, which will be passed to the `aggregator` function.

Returns (hexagons, values) for those values for which `filter_values(value) == true`.

# The aggregator
the aggregator is a closure (or function) `(DataFrames.DataFrameRow, SpatialIndexing.RTree) -> Vector{Float64}`, which calculates the
contribution of the values in the given `row` towards the total value of each hexagonal cell, the index of the return
vector corresponds to the hexagon. In the end, all of these contributions are added to give the final value.

A few aggregators will be implemented below, prefixed with `aggregator_dataframe_`.

# Example
To get the area of the buildings given as polygons in each hexagon, you can do:
```julia
    hexes, values = hexagon_histogram(buildings, 50; filter_values=(>(0.0))) do r, hextree
        values = zeros(length(hextree))
        for inter in intersects_with(hextree, rect_from_geom(r.geometry))
            if ArchGDAL.intersects(inter.val.prep, r.geometry)
                values[inter.id] += ArchGDAL.geomarea(ArchGDAL.intersection(inter.val.orig, r.geometry))
            end
        end
        return values
    end
```

# Drawbacks
Note that this implementation only allows for the calculation of aggregations which are linear in each row. To get nonlinear
values, you currently have to decompose the values you are after into multiple `hexagon_histogram` calls, and build the value
yourself. If you want for example the total building height divided by the number of buildings in each hex cell, you would have
calculate them separately, and do the division afterwards. Also, all things that are not expressed as addition are not going to
work. Things such as the maximum height of a building withing the hexagon.

# Future
Most of this feels like it could feasibly be written as a `mapreduce`...

Somehow, it would be nicer if we were to transform the inner loop into one over the hexagons. As such, every aggregation function
would be possible, and this in general makes a little bit more sense. For that to work, we would have to somehow build an RTree
out of the DataFrame. Which would be possible, I guess, but a bit more work that this thing here.

There is a lot of nearly duplicate code going on here. Not sure what I can do about that though.
"""
function hexagon_histogram(aggregator, gdf::DataFrame, radius; buffer=0, danger_value=10000, filter_values=x -> true)
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

"""

    hexagon_histogram(aggregator, iterator, g::AbstractGraph, radius; buffer=0, danger_value=10000, filter_values=x -> true)

calculates the generalised histogram for data in a graph, by looping over the `iterator`. Most often, this value is either `vertices(g)`
or `edges(g)`. `g` is expected to have the following props: `:center_lon, :center_lat, :crs`.

# The aggregator
now receives `(i, g, hextree)` as arguments, where `i` is the current state of the `iterator`, `g` is the graph, and `hextree` is the
RTree of hexagons. Apart from that, it is expected to behave in the same way as the one from the `DataFrame` version of this function.

# Example
To get the number of vertices in a hexagon, you can do something like:
```julia
    hexes, values = hexagon_histogram(Graphs.vertices(g), g, 50) do vert, g, hextree
        values = zeros(length(hextree))
        for inter in intersects_with(hextree, rect_from_geom(get_prop(g, vert, :pointgeom)))
            values[inter.id] += 1
        end
        return values
    end
```

All other statements given there do apply as well. Aggregators for this method are prefixed with `aggregator_graph_`
"""
function hexagon_histogram(aggregator, iterator, g::AbstractGraph, radius; buffer=0, danger_value=10000, filter_values=x -> true)
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

"""

    aggregator_dataframe_polygon_area(row, hextree)

aggregator to get the area of polygonal data in `row.geometry` in each hexagon.
"""
function aggregator_dataframe_polygon_area(row, hextree)
    values = zeros(length(hextree))
    for inter in intersects_with(hextree, rect_from_geom(row.geometry))
        if ArchGDAL.intersects(inter.val.prep, row.geometry)
            values[inter.id] += ArchGDAL.geomarea(ArchGDAL.intersection(inter.val.orig, row.geometry))
        end
    end
    return values
end

"""

    aggregator_graph_vertex_count(vert, g, hextree)

aggregator to get the number of vertices of the graph `g` in each hexagon. Usese the `:pointgeom` property of the graph.
"""
function aggregator_graph_vertex_count(vert, g, hextree)
    values = zeros(length(hextree))
    for inter in intersects_with(hextree, rect_from_geom(get_prop(g, vert, :pointgeom)))
        values[inter.id] += 1
    end
    return values
end