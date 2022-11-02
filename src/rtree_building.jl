function build_rtree(geocolumn)
    rt = RTree{Float64, 2}(Int, NamedTuple{(:orig, :prep), Tuple{ArchGDAL.IGeometry{ArchGDAL.wkbPolygon}, ArchGDAL.IPreparedGeometry}})
    for (i, geom) in enumerate(geocolumn)
        bbox = rect_from_geom(geom)
        insert!(rt, bbox, i, (orig=geom, prep=ArchGDAL.preparegeom(geom)))
    end
    return rt
end
