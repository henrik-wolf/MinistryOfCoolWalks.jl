"""
    rect_from_geom(geom)

builds `SpatialIndexing.Rect` with the extent of the geomerty `geom`.
"""
function rect_from_geom(geom)
    extent = GeoInterface.extent(geom)
    x, y = values(extent)
    ll = (x[1], y[1])  # less beautiful, but typestable
    ur = (x[2], y[2])
    return SpatialIndexing.Rect(ll, ur)
end

"""
    build_rtree(geo_arr)

builds `SpatialIndexing.RTree{Float64, 2}` from an array containing `ArchGDAL.wkbPolygon`s. The value of an entry in the RTree is a named tuple with:
`(orig=original_geometry,prep=prepared_geometry)`. `orig` is just the original object, an element from `geo_arr`, where `prep` is the prepared geometry,
derived from `orig`. The latter one can be used in a few `ArchGDAL` functions to get higher performance, for example in intersection testing, because
relevant values get precomputed and cashed in the prepared geometry, rather than precomputed on every test.
"""
function build_rtree(geo_arr)
    rt = RTree{Float64, 2}(Int, NamedTuple{(:orig, :prep), Tuple{ArchGDAL.IGeometry{ArchGDAL.wkbPolygon}, ArchGDAL.IPreparedGeometry}})
    @showprogress 1 "building r tree" for (i, geom) in enumerate(geo_arr)
        bbox = rect_from_geom(geom)
        insert!(rt, bbox, i, (orig=geom, prep=ArchGDAL.preparegeom(geom)))
    end
    return rt
end
