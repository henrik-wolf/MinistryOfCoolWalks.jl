using ArchGDAL
using Plots
using GeoInterface
using MinistryOfCoolWalks
using ShadowGraphs
using Graphs
using MetaGraphs

function project_local!(geom::ArchGDAL.IGeometry, center_lon, center_lat)
    projstring = "+proj=tmerc +lon_0=$center_lon +lat_0=$center_lat"
    src = ArchGDAL.getspatialref(geom)
    dest = ArchGDAL.importPROJ4(projstring)
    ArchGDAL.createcoordtrans(src, dest) do trans
        ArchGDAL.transform!(geom, trans)
    end
end
_, g = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
lines_normal = add_shadow_intervals!(g, shadows)  # takes about 0:11 minutes

line_ref = first([get_prop(g, edge, :shadowgeom) for edge in edges(g) if has_prop(g, edge, :osm_id) && get_prop(g, edge, :osm_id) == 29387571])
lines = project_local!(ArchGDAL.clone(line_ref), -1, 53)

distances = [ArchGDAL.distance(l1, l2) for l1 in getgeom(lines), l2 in getgeom(lines)]


# code for drawing the distance matrix for overlapping lines
begin
    p1 = plot(ratio=1)
    #plot!(p1, lines, label="linear", lw=8, alpha=0.2)
    for (i, line) in enumerate(getgeom(lines))
        plot!(p1, line, lw=8, alpha=0.6, label=(i, ngeom(line)), ms=4, m=:o)
    end
    p2 = heatmap(distances, transpose=false, yflip=true, clim=(0,3))
    plot(p1, p2, size=(1000, 1500), layout=(2,1))
end