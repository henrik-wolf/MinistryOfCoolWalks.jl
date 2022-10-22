function build_rtree(geocolumn)
    rt = RTree{Float64, 2}(NamedTuple{(:orig, :prep), Tuple{ArchGDAL.IGeometry, ArchGDAL.IPreparedGeometry}})
    for geom in geocolumn
        bbox = rect_from_geom(geom)
        insert!(rt, bbox, (orig=geom, prep=ArchGDAL.preparegeom(geom)))
    end
    return rt
end
