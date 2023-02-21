"""

    combine_lines(a, b, min_dist)

combines two lines a and b at the ends where they are closer than `min_dist` apart. This assumes, that a and b are (much) longer
than `min_dist`. If not, weird edge cases may arrise.

If `a ⊂ b`, returns `b`, if `b ⊂ a` returns `a`. Otherwise, returns all nodes of `a`, concatenated with all nodes of `b`,
which are further away from `a` than `min_dist`. If a and b form a circle, special care is taken to not mess up the order.
"""
function combine_lines(a, b, min_dist)
    a_points2b = [ArchGDAL.distance(p, b) for p in getgeom(a)]
    b_points2a = [ArchGDAL.distance(a, p) for p in getgeom(b)]

    # check if one line is fully contained in the other
    if ArchGDAL.contains(ArchGDAL.buffer(b, min_dist, 2), a)
        return b
    elseif ArchGDAL.contains(ArchGDAL.buffer(a, min_dist, 2), b)
        return a
    else
        # FIVE possible cases:
        # - overlap is at the end of a and b
        # - overlap is at the start of a and b
        # - overlap is at the start of a and end of b
        # - overlap is at the end of a and start of b
        # - overlap is at the end AND start of a and b
        a_indices = a_points2b[end] < min_dist ? (1:1:ngeom(a)) : (ngeom(a):-1:1)
        b_indices = b_points2a[1] < min_dist ? (1:1:ngeom(b)) : (ngeom(b):-1:1)
        # check if lines form circle (start and end of a is close to b and start and end of b is close to a)
        # the case where they are the same is already captured above
        closing_cycle = a_points2b[1] < min_dist && a_points2b[end] < min_dist && b_points2a[1] < min_dist && b_points2a[end] < min_dist
        # if the lines close a circle and at least one point of b (which gets joined into a) is further away from a than min_dist.
        # (otherwise, we just need to close the loop, all points of b get skipped further down)
        if closing_cycle && any(b_points2a .> min_dist)
            # figure out correct direction to go through b
            # a will be walked through forwards
            first_high_b = findfirst(>(min_dist), b_points2a)
            last_high_b = findlast(>(min_dist), b_points2a)

            if first_high_b isa Nothing || last_high_b isa Nothing
                @show first_high_b
                @show last_high_b
                @show a_points2b
                @show b_points2a

                println(ArchGDAL.toWKT(a))
                println(ArchGDAL.toWKT(b))
            end

            segment_first = ArchGDAL.createlinestring()
            ArchGDAL.addpoint!(segment_first, getcoord(getgeom(b, first_high_b - 1))...)
            ArchGDAL.addpoint!(segment_first, getcoord(getgeom(b, first_high_b))...)

            segment_last = ArchGDAL.createlinestring()
            ArchGDAL.addpoint!(segment_last, getcoord(getgeom(b, last_high_b))...)
            ArchGDAL.addpoint!(segment_last, getcoord(getgeom(b, last_high_b + 1))...)

            a_end = getgeom(a, ngeom(a))

            first_contained = ArchGDAL.contains(ArchGDAL.buffer(segment_first, min_dist, 2), a_end)
            last_contained = ArchGDAL.contains(ArchGDAL.buffer(segment_last, min_dist, 2), a_end)

            if first_contained && !last_contained
                b_indices = 1:1:ngeom(b) |> collect
            elseif last_contained && !first_contained
                b_indices = ngeom(b):-1:1 |> collect
            else
                throw(ErrorException("the end point of a was $(first_contained ? "contained in both" : "not contained in either") one of the intervals it should have been contained in."))
            end
        end

        combined = ArchGDAL.createlinestring()::ArchGDAL.IGeometry{ArchGDAL.wkbLineString}
        for a_index in a_indices
            a_point = getgeom(a, a_index)::ArchGDAL.IGeometry{ArchGDAL.wkbPoint}
            ArchGDAL.addpoint!(combined, getcoord(a_point)...)
        end
        for b_index in b_indices
            b_points2a[b_index] < min_dist && continue
            ArchGDAL.addpoint!(combined, getcoord(getgeom(b, b_index)::ArchGDAL.IGeometry{ArchGDAL.wkbPoint})...)
        end
        if closing_cycle  # the above cuts off all the stuff close to the other line,therefore we just add the final point
            ArchGDAL.addpoint!(combined, getcoord(getgeom(combined, 1)::ArchGDAL.IGeometry{ArchGDAL.wkbPoint})...)
        end
        # we could do some geometry reduction here? (point which are on a line between other points)
        return combined
    end
end


"""

    combine_along_tree(tree, start_node, lines, min_dist)

recursively combines the `lines` at leafs in `tree` with the nodes one order up, 
starting (as in, the recursion starts here. This node gets combined last) at the root `start_node`.
The min_dist is needed to figure out how the lines should be combined. (This dependency could maybe be removed...)
"""
function combine_along_tree(tree, start_node, lines, min_dist)
    mapfoldl(start -> combine_along_tree(tree, start, lines, min_dist),
        (a, b) -> combine_lines(a, b, min_dist),
        neighbors(tree, start_node);
        init=lines[start_node])
end


"""

    rebuild_lines(lines::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}, min_dist)::EdgeGeomType
    rebuild_lines(lines, min_dist)::EdgeGeomType

calculates the union of lines in a (multi) linestring, merging lines which are closer than `min_dist` to one another.

We calculate the adjacency matrix of all lines, build a network with edges where the distance between edges `< min_dist`,
calculate a dfs tree for each connected component and recursively combine the linestrings at the leafs with the linestrings
one level up.
"""
function rebuild_lines(lines::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}, min_dist)::EdgeGeomType
    if ngeom(lines) == 1
        # this should clone the geometry
        return getgeom(lines, 1)
    else
        return rebuild_lines(getgeom(lines), min_dist)
    end
end

function rebuild_lines(lines, min_dist)::EdgeGeomType
    lines = collect(lines)  # make sure lines are indexable
    nlines = length(lines)
    adjacency = falses(nlines, nlines)
    for j in 1:nlines
        for i in 1:nlines
            if j == i
                adjacency[i, j] = false
            elseif j < i  # frist doing columns, the copy over more and more.
                adjacency[i, j] = ArchGDAL.distance(lines[i], lines[j]) < min_dist
            else
                adjacency[i, j] = adjacency[j, i]
            end
        end
    end

    # TODO: this calculates every distance twice... but the syntax is absoulutely gorgeous
    #=
    adjacency = [GeoInterface.distance(a,b) < min_dist for a in lines, b in lines]
    for i in first(size(adjacency))
        adjacency[i,i] = false
    end
    =#

    neighbor_graph = SimpleGraph(adjacency)
    component_starts = first.(connected_components(neighbor_graph))
    trees = map(start -> dfs_tree(neighbor_graph, start), component_starts)
    disjunct_lines = map(trees, component_starts) do tree, start_node
        combine_along_tree(tree, start_node, lines, min_dist)
    end
    if length(disjunct_lines) == 1
        return first(disjunct_lines)
    else
        ret_multiline = ArchGDAL.createmultilinestring()::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}
        for geom in disjunct_lines
            ArchGDAL.addgeom!(ret_multiline, geom)
        end
        return ret_multiline
    end
end



"""

    get_length_by_buffering(geom, buffer, points, edge)

approximates the "non overlapping" length of overlapping linestrings by buffering `geom` with a buffer of size `buffer` and
points `points`, specifying how many points should be used to approximate bends of 90 degrees. After buffering, we calculate the area
and divide by the twice the buffer width (buffer is radius), after subtracting the area of the endcaps.
(This function is currently not in use.)
"""
function get_length_by_buffering(geom, buffer, points, edge)
    surface = ArchGDAL.buffer(geom, buffer, points)
    if buffer > 1e-2
        throw(DomainError("buffer zone too large."))
    end
    if ngeom(surface) == 0
        if points < 100
            #@warn "somethow, some geom did not produce a usable surface. Increasing the points"
            return get_length_by_buffering(geom, buffer, 20 + points, edge)
        else
            @warn "increasing the points did not work, doubling buffer for edge $edge"
            return get_length_by_buffering(geom, 2 * buffer, 1, edge)
        end
    else
        area = 1 / 2 * 4 * points * buffer^2 * sin(2π / (4 * points))  # area of regular polygon with 4*points corners
        ngeoms = geomtrait(surface) isa MultiPolygonTrait ? ngeom(surface) : 1
        total_endcap_area = ngeoms * area  # every polygon adds two halves of a regular polygon with 4*points at each end.
        return (ArchGDAL.geomarea(surface) - total_endcap_area) / 2buffer
    end
end


"""

    join_shadow_without_union!(full_shadow, new_shadow::ArchGDAL.IGeometry{ArchGDAL.wkbLineString})
    join_shadow_without_union!(full_shadow, new_shadow::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString})

adds `new_shadow` to `full_shadow`, skipping empty linestrings.
"""
function join_shadow_without_union!(full_shadow, new_shadow::ArchGDAL.IGeometry{ArchGDAL.wkbLineString})
    if ngeom(new_shadow) > 1
        ArchGDAL.addgeom!(full_shadow, new_shadow)
    end
    return full_shadow
end

function join_shadow_without_union!(full_shadow, new_shadow::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString})
    for i in getgeom(new_shadow)
        join_shadow_without_union!(full_shadow, i)
    end
    return full_shadow
end


"""

    add_shadow_intervals!(g, shadows; clear_old_shadows=false)

adds the intersection of the polygons in dataframe `shadows` with metadata `"center_lon"` and `"center_lat"` and the geometry in
the edgeprop `:edgegeom` of graph `g` to `g`. This operation can be repeated on the same graph with various shadows.

If `clear_old_shadows` is true, all possible, preexisting effects of previous executions of this function are reset. This way, a once loaded
graph can be reused for all experiments.

After this operation, all non-helper edges will have the additional property of ':shadowed_length'. This value is zero, if there is
no shadow cast on the edge. If there is a shadow cast on the edge, the edge will have an additional property, ':shadowgeom', representing
the geometry of the street in the shadow.
"""
function add_shadow_intervals!(g, shadows; clear_old_shadows=false)
    MIN_DIST = 1e-4  # TODO: find out what a reasonable value would be for this.

    # project all stuff into local system
    center_lon = metadata(shadows, "center_lon")::Float64
    center_lat = metadata(shadows, "center_lat")::Float64

    # project all stuff into local system
    project_local!(shadows.geometry, center_lon, center_lat)
    project_local!(g, center_lon, center_lat)

    df = DataFrame()

    local_crs = get_prop(g, :crs)
    shadow_tree = build_rtree(shadows.geometry)

    #return shadow_tree
    @showprogress 1 "adding shadows" for edge in edges(g)
        !has_prop(g, edge, :edgegeom) && continue  # skip helpers

        # add or reset all numeric props on edges which not yet have them
        if !has_prop(g, edge, :shadowed_length) || clear_old_shadows
            set_prop!(g, edge, :shadowed_length, 0.0)
        end
        if !has_prop(g, edge, :buffer_shadowed_length) || clear_old_shadows
            set_prop!(g, edge, :buffer_shadowed_length, 0.0)
        end

        linestring = get_prop(g, edge, :edgegeom)::EdgeGeomType
        linestring_rect = rect_from_geom(linestring)

        total_shadow_part_lengths = 0.0
        full_shadow_segmented = ArchGDAL.createmultilinestring()::ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}
        intersecting_elements = SpatialIndexing.intersects_with(shadow_tree, linestring_rect)
        TreeIntersectionType = eltype(intersecting_elements)
        for spatialElement::TreeIntersectionType in intersecting_elements
            #for row in eachrow(shadows)
            prep_geom = spatialElement.val.prep
            #prep_geom = ArchGDAL.preparegeom(row.geometry)

            not_inter = !ArchGDAL.intersects(prep_geom, linestring)  # prepared geometry has only two functions it actually works with.
            not_inter && continue  # skip disjoint geometry

            orig_geom = spatialElement.val.orig#::ArchGDAL.IGeometry{ArchGDAL.wkbPolygon}
            #orig_geom = row.geometry

            part_in_shadow = ArchGDAL.intersection(orig_geom, linestring)::EdgeGeomType
            total_shadow_part_lengths += ArchGDAL.geomlength(part_in_shadow)

            join_shadow_without_union!(full_shadow_segmented, part_in_shadow)
        end

        # skip all edges not in shade
        if total_shadow_part_lengths == 0.0
            # remove shadowgeom on current edge not in shade and if clearing is active
            if clear_old_shadows && has_prop(g, edge, :shadowgeom)
                rem_prop!(g, edge, :shadowgeom)
                rem_prop!(g, edge, :shadowgeom_segmented)
            end
            continue
        end

        # add the relevant properties to the graph if not allready there (and reset the geometry if clearing is active)
        if !has_prop(g, edge, :shadowgeom) || clear_old_shadows
            set_prop!(g, edge, :shadowgeom, ArchGDAL.createlinestring())
        end

        # update the relevant properties of the graph
        full_shadow_previous = get_prop(g, edge, :shadowgeom)
        join_shadow_without_union!(full_shadow_segmented, full_shadow_previous)
        reinterp_crs!(full_shadow_segmented, local_crs)

        set_prop!(g, edge, :shadowgeom_segmented, full_shadow_segmented)

        full_shadow = rebuild_lines(full_shadow_segmented, MIN_DIST)
        reinterp_crs!(full_shadow, local_crs)
        set_prop!(g, edge, :shadowgeom, full_shadow)

        length_in_shadow = ArchGDAL.geomlength(full_shadow)
        set_prop!(g, edge, :shadowed_length, length_in_shadow)
        set_prop!(g, edge, :buffer_shadowed_length, get_length_by_buffering(full_shadow_segmented, 1e-3, 2, edge))

        push!(df, Dict(
                :edge => get_prop(g, edge, :osm_id),
                :sl => get_prop(g, edge, :shadowed_length),
                :fl => get_prop(g, edge, :full_length),
                :g_edge => edge
            ); cols=:union)
    end
    #project all stuff back
    project_back!(shadows.geometry)
    project_back!(g)
    return df
end


"""

check_shadow_angle_integrity(g, max_angle)

checks, if all angles in shadows in `g` are less than `max_angle` (in radians). If not, prints a warning.
Used to test if the shadow joining works as intended.
"""
function check_shadow_angle_integrity(g, max_angle)
    df = DataFrame((edge=e, shadowgeom=get_prop(g, e, :shadowgeom)) for e in filter_edges(g, :shadowgeom))
    df.angles = angles_in.(df.shadowgeom)
    df.all_less = all_less_than.(df.angles, max_angle)
    df.max_angle = map(a -> length(a) == 0 ? 0.0 : maximum(a), df.angles)
    no_problem = all(df.all_less)
    max_enc_angle = maximum(df.max_angle)
    if no_problem
        @info "all angles between segments in the :shadowgeom field are less than $(max_angle)! (largest encountered angle: $max_enc_angle)"
    else
        filter!(:all_less => !, df)
        @warn "$(nrow(df)) edges have angles larger than $max_angle. Returning problematic values."
    end
    return no_problem, df
end


"""

    angles_in(line)
    angles_in(::MultiLineStringTrait, lines)
    angles_in(::LineStringTrait, line)

calculates all angles between segments in `line`. Result in radians.
"""
angles_in(line) = angles_in(geomtrait(line), line)

function angles_in(::MultiLineStringTrait, lines)
    mapfoldl(angles_in, vcat, getgeom(lines))
end

function angles_in(::LineStringTrait, line)
    ngeom(line) < 3 && return Float64[]
    points = getgeom(line) .|> getcoord .|> collect
    x = getindex.(points, 1)
    y = getindex.(points, 2)
    dx = diff(x)
    dy = diff(y)
    l = @. sqrt(dx^2 + dy^2)
    angle = @. clamp((dx[1:end-1] * dx[2:end] + dy[1:end-1] * dy[2:end]) / (l[1:end-1] * l[2:end]), -1.0, 1.0)
    acos.(angle)
end

"""

    all_less_than(angles, max_angle)

checks if all values in `angles` are less than `max_angle`.
"""
all_less_than(angles, max_angle) = mapreduce(<(max_angle), &, angles, init=true)

"""

    npoints(line)
    npoints(::LineStringTrait, line)
    npoints(::MultiLineStringTrait, line)

calculates the number of points in a line or multiline.
"""
npoints(line) = npoints(geomtrait(line), line)

npoints(::LineStringTrait, line) = ngeom(line)
npoints(::MultiLineStringTrait, line) = mapreduce(ngeom, +, getgeom(line))