function cast_shadow(buildings_df, height_key, sun_direction::AbstractArray)
    @assert sun_direction[3] > 0 "the sun is below or on the horizon. Everything is in shadow."
    #@info "this function assumes you geometry beeing in a suitable crs to do projections"

    project_local!(buildings_df.geometry, metadata(buildings_df, "center_lon"), metadata(buildings_df, "center_lat"))

    shadow_df = DataFrame(geometry=typeof(buildings_df.geometry)(), id=typeof(buildings_df.id)())
    
    for key in metadatakeys(buildings_df)
        metadata!(shadow_df, key, metadata(buildings_df, key); style=:note)
    end

    # find offset vector
    offset_vector = - sun_direction ./ sun_direction[3]
    offset_vector[3] = 0

    @showprogress 1 "calculating shadows" for row in eachrow(buildings_df)
        o = getproperty(row, height_key) * offset_vector
        lower_ring = GeoInterface.getgeom(row.geometry, 1)
        upper_ring = GeoInterface.getgeom(row.geometry, 1)

        # move upper ring to the projected position
        for i in 0:ArchGDAL.ngeom(upper_ring)-1
            x = ArchGDAL.getx(upper_ring, i) + o[1]
            y = ArchGDAL.gety(upper_ring, i) + o[2]
            ArchGDAL.setpoint!(upper_ring, i, x, y)
        end

        # build vector of (projected) outer polygons
        outer_shadow = ArchGDAL.createpolygon()
        for i in 0:ArchGDAL.ngeom(upper_ring) - 2
            pl1 = ArchGDAL.getpoint(lower_ring, i)[1:end-1]
            pu1 = ArchGDAL.getpoint(upper_ring, i)[1:end-1]
            pl2 = ArchGDAL.getpoint(lower_ring, i+1)[1:end-1]
            pu2 = ArchGDAL.getpoint(upper_ring, i+1)[1:end-1]
            # buffer to prevent numerical problems when taking union of two polygons sharing only an edge
            # comes at the cost of twice the polycount in the final shadow
            outer_poly = ArchGDAL.buffer(ArchGDAL.createpolygon([pl1, pl2, pu2, pu1, pl1]), 0.001, 1)
            outer_shadow = ArchGDAL.union(outer_shadow, outer_poly)
        end
        holeless_lower_poly = ArchGDAL.createpolygon()
        ArchGDAL.addgeom!(holeless_lower_poly, lower_ring)
        
        crs = ArchGDAL.getspatialref(row.geometry)
        ArchGDAL.createcoordtrans(crs, crs) do trans
            ArchGDAL.transform!(outer_shadow, trans)
            ArchGDAL.transform!(holeless_lower_poly, trans)
        end
        

        full_shadow = ArchGDAL.union(outer_shadow, holeless_lower_poly)        
        push!(shadow_df, [full_shadow, row.id])
    end

    project_back!(buildings_df.geometry)
    project_back!(shadow_df.geometry)

    return shadow_df
end

rebuild_lines(lines, min_dist) = rebuild_lines(geomtrait(lines), lines, min_dist)
rebuild_lines(::LineStringTrait, lines, min_dist) = lines
rebuild_lines(::MultiLineStringTrait, lines, min_dist) = rebuild_lines(nothing, getgeom(lines), min_dist)  # not sure if I need to collect...
function rebuild_lines(::Nothing, lines, min_dist)
    lines = collect(lines)  # make sure lines are indexable
    # TODO: this calculates every distance twice... but the syntax is absoulutely gorgeous
    adjacency = [GeoInterface.distance(a,b) < min_dist for a in lines, b in lines]
    for i in first(size(adjacency))
        adjacency[i,i] = false
    end
    neighbor_graph = SimpleGraph(adjacency)
    component_starts = first.(connected_components(neighbor_graph))
    trees = map(start->dfs_tree(neighbor_graph, start), component_starts)
    return map(trees, component_starts) do tree, start_node
        combine_along_tree(tree, start_node, lines)
    end
end

function combine_along_tree(tree, start_node, lines)
    mapfoldl(start->combine_along_tree(tree, start, lines), combine_lines, neighbors(tree, start_node); init=lines[start_node])
end

function combine_lines(a, b)
    return (a,b)
end

function get_length_by_buffering(geom, buffer, points, edge)
    surface = ArchGDAL.buffer(geom, buffer, points)
    if buffer > 1e-2
        throw(DomainError("buffer zone too large."))
    end
    if ngeom(surface) == 0
        if points < 100
            #@warn "somethow, some geom did not produce a usable surface. Increasing the points"
            return get_length_by_buffering(geom, buffer, 20+points, edge)
        else
            @warn "increasing the points did not work, doubling buffer for edge $edge"
            return get_length_by_buffering(geom, 2*buffer, 1, edge)
        end
    else
        area = 1/2 * 4*points * buffer^2 * sin(2π/(4*points))  # area of regular polygon with 4*points corners
        ngeoms = geomtrait(surface) isa MultiPolygonTrait ? ngeom(surface) : 1
        total_endcap_area = ngeoms * area  # every polygon adds two halves of a regular polygon with 4*points at each end.
        return (ArchGDAL.geomarea(surface) - total_endcap_area) / 2buffer
    end
end

# function to add shadow intervals to meta graph g, from dataframe shadows with column :geometry
# adds the following data to the edge props: -shadowed_length, -shadowgeom, shadowed_part_length (only for debugging)
# shadows is expected to have center_lon and center_lat in its metadata. This is used to project all geometry to a locally flat crs
function add_shadow_intervals!(g, shadows; method=:buffer)
    BUFFER = 1e-4  # TODO: fix this value at something reasonable. also... maybe reconstruct the lines anyway??

    # project all stuff into local system
    project_local!(shadows.geometry, metadata(shadows, "center_lon"), metadata(shadows, "center_lat"))
    project_local!(g, metadata(shadows, "center_lon"), metadata(shadows, "center_lat"))
    df = DataFrame()
    @showprogress 0.2 "adding shadows" for edge in edges(g)
        !has_prop(g, edge, :edgegeom) && continue  # skip helpers
        linestring = get_prop(g, edge, :edgegeom)

        shadow_lines = ArchGDAL.IGeometry[]
        for shadow_row in eachrow(shadows)
            ArchGDAL.disjoint(shadow_row.geometry, linestring) && continue  # skip disjoint geometry

            part_in_shadow = ArchGDAL.intersection(shadow_row.geometry, linestring)
            push!(shadow_lines, part_in_shadow)
        end
        length(shadow_lines) == 0 && continue  # skip all edges not in the shadow

        # add the relevant properties to the graph if not allready there
        if !has_prop(g, edge, :shadowed_part_length)
            set_prop!(g, edge, :shadowed_part_length, 0)
        end

        if !has_prop(g, edge, :shadowgeom)
            set_prop!(g, edge, :shadowgeom, ArchGDAL.createlinestring())
        end

        if !has_prop(g, edge, :shadowed_length)
            set_prop!(g, edge, :shadowed_length, 0)
        end

        # update the relevant properties of the graph
        total_shadow_part_lengths = mapreduce(ArchGDAL.geomlength, +, shadow_lines; init=get_prop(g, edge, :shadowed_part_length))
        set_prop!(g, edge, :shadowed_part_length, total_shadow_part_lengths)
        
        full_shadow = foldl(ArchGDAL.union, shadow_lines; init = get_prop(g, edge, :shadowgeom))
        if method === :reconstruct
            full_shadow = clean_up_linestring(full_shadow)
        end
        set_prop!(g, edge, :shadowgeom, full_shadow)

        length_in_shadow = if method === :reconstruct
                            ArchGDAL.geomlength(full_shadow)
                        elseif method === :buffer
                            get_length_by_buffering(full_shadow, BUFFER, 1, edge)
                        end

        set_prop!(g, edge, :shadowed_length, length_in_shadow)

        set_prop!(g, edge, :full_length, ArchGDAL.geomlength(get_prop(g, edge, :edgegeom)))

        diff = get_prop(g, edge, :shadowed_part_length) - length_in_shadow
        if diff < -0.1
            @warn "the sum of the parts length is less than the length of the union for edge $edge (by $diff m)"
            return full_shadow
            #project_back!(shadows.geometry)
            #project_back!(g)
            #return get_prop(g, edge, :shadowgeom)

            #return shadow_lines
        end

        push!(df, Dict(
            :edge=>get_prop(g, edge, :osm_id),
            :sl=>get_prop(g, edge, :shadowed_length),
            :spl=>get_prop(g, edge, :shadowed_part_length),
            :fl=>get_prop(g, edge, :full_length)
        ); cols=:union)
    end
    #project all stuff back
    project_back!(shadows.geometry)
    project_back!(g)
    return df
end


function add_shadow_intervals_linear!(g, shadows)
    # project all stuff into local system
    project_local!(shadows.geometry, metadata(shadows, "center_lon"), metadata(shadows, "center_lat"))
    project_local!(g, metadata(shadows, "center_lon"), metadata(shadows, "center_lat"))
    df = DataFrame()

   @info "union of all shadows" 
    full_shadow = reduce(ArchGDAL.union, shadows.geometry)

    @showprogress 0.2 "adding shadows" for edge in edges(g)
        !has_prop(g, edge, :edgegeom) && continue  # skip helpers
        linestring = get_prop(g, edge, :edgegeom)

        ArchGDAL.disjoint(full_shadow, linestring) && continue  # skip disjoint geometry

        part_in_shadow = ArchGDAL.intersection(full_shadow, linestring)

        # add the relevant properties to the graph if not allready there
        if !has_prop(g, edge, :shadowgeom)
            set_prop!(g, edge, :shadowgeom, ArchGDAL.createlinestring())
        end

        if !has_prop(g, edge, :shadowed_length)
            set_prop!(g, edge, :shadowed_length, 0)
        end

        # update the relevant properties of the graph
        set_prop!(g, edge, :shadowgeom, part_in_shadow)

        union_length = ArchGDAL.geomlength(get_prop(g, edge, :shadowgeom))
        set_prop!(g, edge, :shadowed_length, union_length)

        set_prop!(g, edge, :full_length, ArchGDAL.geomlength(get_prop(g, edge, :edgegeom)))

        push!(df, Dict(
            :edge=>get_prop(g, edge, :osm_id),
            :sl=>get_prop(g, edge, :shadowed_length),
            :fl=>get_prop(g, edge, :full_length)
        ); cols=:union)
    end
    #project all stuff back
    project_back!(shadows.geometry)
    project_back!(g)
    return df
end