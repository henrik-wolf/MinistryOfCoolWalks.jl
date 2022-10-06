function project_local!(geo_column, center_lon, center_lat)
    projstring = "+proj=tmerc +lon_0=$center_lon +lat_0=$center_lat"
    src = ArchGDAL.getspatialref(first(geo_column))
    dest = ArchGDAL.importPROJ4(projstring)
    ArchGDAL.createcoordtrans(src, dest) do trans
        for geom in geo_column
            ArchGDAL.transform!(geom, trans)
        end
    end
end

function project_back!(geo_colum)
    src = ArchGDAL.getspatialref(first(geo_colum))
    ArchGDAL.createcoordtrans(src, OSM_ref[]) do trans
        for geom in geo_colum
            ArchGDAL.transform!(geom, trans)
        end
    end
end