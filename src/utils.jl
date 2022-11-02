function project_local!(geo_column, center_lon, center_lat)
    projstring = "+proj=tmerc +lon_0=$center_lon +lat_0=$center_lat"
    #println(projstring)
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
    #println(projstring)
    src = get_prop(g, :crs)
    dest = ArchGDAL.importPROJ4(projstring)
    ArchGDAL.createcoordtrans(trans->project_graph_edges!(g, trans), src, dest)
    ArchGDAL.createcoordtrans(trans->project_graph_nodes!(g, trans), src, dest)
    set_prop!(g, :crs, dest)
end

function project_back!(g::T) where {T<:AbstractMetaGraph}
    src = get_prop(g, :crs)
    ArchGDAL.createcoordtrans(trans->project_graph_edges!(g, trans), src, OSM_ref[])
    ArchGDAL.createcoordtrans(trans->project_graph_nodes!(g, trans), src, OSM_ref[])
    set_prop!(g, :crs, OSM_ref[])
end

function project_graph_nodes!(g, trans)
    for vertex in vertices(g)
        if has_prop(g, vertex, :pointgeom)
            ArchGDAL.transform!(get_prop(g, vertex, :pointgeom), trans)
        end
    end
end

function project_graph_edges!(g, trans)
    for edge in edges(g)
        if has_prop(g, edge, :edgegeom)
            ArchGDAL.transform!(get_prop(g, edge, :edgegeom)::EdgeGeomType, trans)
        end
        if has_prop(g, edge, :shadowgeom)
            ArchGDAL.transform!(get_prop(g, edge, :shadowgeom)::EdgeGeomType, trans)
        end
    end
end

function rect_from_geom(geom)
    extent = GeoInterface.extent(geom)
    x, y = values(extent)
    ll = (x[1], y[1])  # less beautiful, but typestable
    ur = (x[2], y[2])
    return SpatialIndexing.Rect(ll, ur)
end

# temporary, for working with prepared geometry
ArchGDAL.toWKT(geom::ArchGDAL.AbstractPreparedGeometry) = "PreparedGeometry"

function reinterp_crs!(geom, crs)
    ArchGDAL.createcoordtrans(crs, crs) do trans
        ArchGDAL.transform!(geom, trans)
    end
end
