function rect_from_geom(geom)
    extent = GeoInterface.extent(geom)
    x, y = values(extent)
    ll = (x[1], y[1])  # less beautiful, but typestable
    ur = (x[2], y[2])
    return SpatialIndexing.Rect(ll, ur)
end

function build_rtree(geocolumn)
    rt = RTree{Float64, 2}(Int, NamedTuple{(:orig, :prep), Tuple{ArchGDAL.IGeometry{ArchGDAL.wkbPolygon}, ArchGDAL.IPreparedGeometry}})
    @showprogress 1 "building r tree" for (i, geom) in enumerate(geocolumn)
        bbox = rect_from_geom(geom)
        insert!(rt, bbox, i, (orig=geom, prep=ArchGDAL.preparegeom(geom)))
    end
    return rt
end
