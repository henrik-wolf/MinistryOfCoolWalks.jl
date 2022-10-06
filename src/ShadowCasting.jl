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

    for row in eachrow(buildings_df)
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