function build_rtree(geocolumn)
    rt = RTree{Float64, 2}(typeof(first(geocolumn)))
    for geom in geocolumn
        bbox = rect_from_geom(geom)
        insert!(rt, bbox, geom)
    end
    return rt
end
