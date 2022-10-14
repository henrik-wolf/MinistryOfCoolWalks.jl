using ArchGDAL
using Plots
using GeoInterface
using MinistryOfCoolWalks
using ShadowGraphs
using Graphs
using MetaGraphs
using GraphRecipes

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
size(adj)
[adj[i,i] = false for i in 1:first(size(adj))]

clines = collect(getgeom(lines))[1]
collect(getgeom(clines))


rebuild_lines(getgeom(lines), 0.1)

graphplot(trees[2], names=vertices(trees[2]), markersize=0.3)

neighbors(trees[2], 7)

adj_g = SimpleGraph(adj)
connected_components(adj_g)
t1 = dfs_tree(adj_g, 8)



graphplot(adj_g, curves=false, names=vertices(adj_g), markersize=0.3)
graphplot!(t1, curves=false, names=vertices(t1), markersize=0.3)
neighbors(t1, 8)



function combine(tree, start)
    mapfoldl(n->combine(tree, n), (x,y)->(x,y), neighbors(tree, start); init=start)
end

combine(t1, 8)


heatmap(adj, yflip=true)

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

using Test
@testset "stuff" begin
    @test geomtrait(rebuild_lines(getgeom(lines, 1), 1)) isa LineStringTrait
end