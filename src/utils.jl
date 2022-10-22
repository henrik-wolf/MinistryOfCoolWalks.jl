function project_local!(geo_column, center_lon, center_lat)
    projstring = "+proj=tmerc +lon_0=$center_lon +lat_0=$center_lat"
    src = ArchGDAL.getspatialref(first(geo_column))
    dest = ArchGDAL.importPROJ4(projstring)
    ArchGDAL.createcoordtrans(trans->project_geo_column!(geo_column, trans), src, dest)
end

function project_back!(geo_column)
    src = ArchGDAL.getspatialref(first(geo_column))
    ArchGDAL.createcoordtrans(trans->project_geo_column!(geo_column, trans), src, OSM_ref[])
end

function project_geo_column!(geo_column, trans)
    for geom in geo_column
        ArchGDAL.transform!(geom, trans)
    end
end

function project_local!(g::T, center_lon, center_lat) where {T<:AbstractMetaGraph}
    projstring = "+proj=tmerc +lon_0=$center_lon +lat_0=$center_lat"
    src = get_prop(g, :crs)
    dest = ArchGDAL.importPROJ4(projstring)
    ArchGDAL.createcoordtrans(trans->project_graph_edges!(g, trans), src, dest)
    set_prop!(g, :crs, dest)
end

function project_back!(g::T) where {T<:AbstractMetaGraph}
    src = get_prop(g, :crs)
    ArchGDAL.createcoordtrans(trans->project_graph_edges!(g, trans), src, OSM_ref[])
    set_prop!(g, :crs, OSM_ref[])
end


function project_graph_edges!(g, trans)
    for edge in edges(g)
        if has_prop(g, edge, :edgegeom)
            ArchGDAL.transform!(get_prop(g, edge, :edgegeom), trans)
        end
        if has_prop(g, edge, :shadowgeom)
            ArchGDAL.transform!(get_prop(g, edge, :shadowgeom), trans)
        end
    end
end

function rect_from_geom(geom)
    extent = GeoInterface.extent(geom)
    return SpatialIndexing.Rect(values(extent)...)
end

# temporary, for working with prepared geometry
ArchGDAL.toWKT(geom::ArchGDAL.AbstractPreparedGeometry) = error("trading a segfault for an error")