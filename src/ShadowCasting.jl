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

# function to add shadow intervals to meta graph g, from dataframe shadows with column :geometry
# adds the following data to the edge props: -shadowed_length, -shadowgeom, shadowed_part_length (only for debugging)
function add_shadow_intervals!(g, shadows)
    df = DataFrame()
    @showprogress 0.2 "adding shadows" for edge in edges(g)
        !has_prop(g, edge, :geolinestring) && continue  # skip helpers
        linestring = get_prop(g, edge, :geolinestring)

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
        total_shadow_part_lengths = mapreduce(ArchGDAL.geomlength, +, shadow_lines)
        set_prop!(g, edge, :shadowed_part_length, get_prop(g, edge, :shadowed_part_length) + total_shadow_part_lengths)
        
        full_shadow = foldl(ArchGDAL.union, shadow_lines)
        set_prop!(g, edge, :shadowgeom, ArchGDAL.union(get_prop(g, edge, :shadowgeom), full_shadow))

        set_prop!(g, edge, :shadowed_length, ArchGDAL.geomlength(get_prop(g, edge, :shadowgeom)))

        push!(df, Dict(
            :edge=>get_prop(g, edge, :osm_id), 
            :shadow=>full_shadow, 
            :parts_length=>total_shadow_part_lengths,
            :union_length=>ArchGDAL.geomlength(get_prop(g, edge, :shadowgeom))
            ); cols=:union)
    end
    return df
end