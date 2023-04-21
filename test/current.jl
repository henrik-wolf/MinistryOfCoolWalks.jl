using MinistryOfCoolWalks
using ArchGDAL
using ShadowGraphs
using CompositeBuildings
using TreeLoaders
using Graphs
import Graphs: vertices, neighbors
using MetaGraphs
using Folium
using GeoInterface
using DataFrames
using CoolWalksUtils
using JET
using BenchmarkTools
using Plots
using Hexagons
using SpatialIndexing

using BenchmarkTools

datapath = joinpath(homedir(), "Desktop/Masterarbeit/data/Nottingham/")
buildings = load_british_shapefiles(joinpath(datapath, "Nottingham.shp"); bbox=(minlon=-1.2, minlat=52.89, maxlon=-1.165, maxlat=52.92))
g = shadow_graph_from_file(joinpath(datapath, "clifton/test_clifton_bike.json"); network_type=:bike)



sort!(buildings, :geometry, by=b -> ngeom(getgeom(b, 1)))
buildings.geotypes = ngeom.(buildings.geometry)
gb = groupby(buildings, :geotypes)
gb[2]
shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.4])
trees = load_nottingham_trees(joinpath(datapath, "trees/trees_full_rest.csv"); bbox=(minlon=-1.2, minlat=52.89, maxlon=-1.165, maxlat=52.92))

get_prop(g, :center_lon)

@benchmark hexagon_histogram(Graphs.vertices(g), g, 50, filter_values=(>(0))) do vert, g, hextree
    values = zeros(length(hextree))
    for inter in intersects_with(hextree, rect_from_geom(get_prop(g, vert, :pointgeom)))
        if ArchGDAL.intersects(inter.val.orig, get_prop(g, vert, :pointgeom))
            values[inter.id] += 1
        end
    end
    return values
end

@benchmark hexagon_histogram2(g, 50, filter_values=(>(0))) do inters, hex
    count(i -> i.val.type == :vertex, inters)
end

@benchmark hexagon_histogram(buildings, 50, filter_values=(>(0))) do row, hextree
    values = zeros(length(hextree))
    for inter in intersects_with(hextree, rect_from_geom(row.geometry))
        if ArchGDAL.intersects(inter.val.prep, row.geometry)
            values[inter.id] += ArchGDAL.geomarea(ArchGDAL.intersection(inter.val.orig, row.geometry))
        end
    end
    return values
end

@benchmark hexagon_histogram2(buildings, 50, filter_values=(>(0))) do inters, hex
    mapreduce(+, inters; init=0.0) do i
        ArchGDAL.geomarea(ArchGDAL.intersection(hex, i.val.orig))
    end
end


hexagon_histogram(buildings, 50, filter_values=(>(0))) do row, hextree
    values = zeros(length(hextree))
    for inter in intersects_with(hextree, rect_from_geom(row.geometry))
        if ArchGDAL.intersects(inter.val.prep, row.geometry)
            values[inter.id] += ArchGDAL.geomarea(ArchGDAL.intersection(inter.val.orig, row.geometry))
        end
    end
    return values
end

@profview hexagon_histogram2(g, 30, filter_values=(>(0))) do inters, hex
    count(i -> i.val.type == :vertex, inters)
end

@benchmark hexagon_histogram2(buildings, 50) do inters, hex
    geom = mapreduce(ArchGDAL.union, inters; init=ArchGDAL.createpolygon()) do i
        ArchGDAL.intersection(hex, i.val.orig)
    end
    reinterp_crs!(geom, ArchGDAL.getspatialref(hex))
end

scatter(v, v2)

begin
    f = draw(h, color=v)
    draw!(f, g, :vertices)
end

hexes, values = hexagon_histogram(Graphs.vertices(g), g, 50) do vert, g, hextree
    values = zeros(length(hextree))
    for inter in intersects_with(hextree, rect_from_geom(get_prop(g, vert, :pointgeom)))
        values[inter.id] += 1
    end
    return values
end


(bh, bv) = hexagon_histogram(MinistryOfCoolWalks.aggregator_dataframe_polygon_area, buildings, 50; filter_values=(>(0.0)))


building_hexes, building_values = hexagon_histogram(buildings, 50, filter_values=(>(0.0))) do r, hextree
    values = zeros(length(hextree))
    for inter in intersects_with(hextree, rect_from_geom(r.geometry))
        if ArchGDAL.intersects(inter.val.prep, r.geometry)
            values[inter.id] += ArchGDAL.geomarea(ArchGDAL.intersection(inter.val.orig, r.geometry))
        end
    end
    return values
end

plot(hexes, fill_z=permutedims(values))
plot(building_hexes, fill_z=permutedims(building_values))

@enter hex(colors[0.4])
maximum(values)

b1, c = zip(buildings.geometry, Iterators.cycle([:red])) |> first

zip(b1, Iterators.cycle([1, 2, 3])) |> collect

b1

buildings
begin
    #colors = cgrad(:inferno)
    f = draw(buildings.geometry, figure_params=Dict(:height => 1000), color=buildings.height_mean, cmap=:inferno, clims=(0, 10))
    draw_colorbar!(f, "Building height", buildings.height_mean, cmap=:inferno, tick_angle=0, label_pad=0.3, margin_top=0.1, margin_bottom=0.1, clims=(0, 10))
    # draw!(f, bh, color=bv)
    #draw!(f, g, :vertices)
    f
end

@which Folium.process_colors(nothing, [1, 2], :extrema)

begin
    f = draw()
    Folium.draw_text!(f, "tset", 0.0, 0.0; angle=90.0, fontsize=40)
    draw!(f, 0.0, 0.0, :circle)
end


icon = Folium.flm.features.DivIcon(icon_size=(250, 3600), icon_anchor=(0, 0), html="<div style=\"background: red;\">testtest</div>")

hexagon_histogram(buildings, r2, 0) do r, hextree
    values = zeros(length(hextree))
    # check for intersection with bounding boxes of hex and geometry
    for res in intersects_with(hextree, rect_from_geom(r.geometry))
        # check if they actually intersect
        if ArchGDAL.intersects(res.val.prep, r.geometry)
            # actually calculate the return values
            values[res.id] = ArchGDAL.intersection(res.val.geom, r.geometry)
        end
    end
    return values
end

hex(cgrad(:inferno)[0.4])

tree_shadows = cast_shadow(trees, tree_param_getter_nottingham, [1.0, -0.5, 0.4])

HexagonTrait

# map only shadows
begin
    fig = draw(tree_shadows.geometry;
        figure_params=dict(:location => (52.904, -1.18), :zoom_start => 14),
        fill_opacity=0.5,
        color="#545454")
    draw!(fig, shadows.geometry; fill_opacity=0.5, color="#545454")
    for row in eachrow(trees)
        tt = "radius: $(row.crown_spread_radius)<br>height: $(row.height_n)<br>common name: $(row.commonname)"
        draw!(fig, row.pointgeom; radius=row.crown_spread_radius, color="#71b36b", fill=true, stroke=false, fill_opacity=0.8, tooltip=tt)
    end
    draw!(fig, buildings.geometry)
    write("shadow_map.html", repr("text/html", fig))
    #draw!(fig, shadows.geometry; fill_opacity=0.5, color=:black)
end

# map only network
begin
    fig = draw(tree_shadows.geometry;
        figure_params=dict(:location => (52.904, -1.18), :zoom_start => 14),
        fill_opacity=0.5,
        color="#545454")
    draw!(fig, shadows.geometry; fill_opacity=0.5, color="#545454")
    for row in eachrow(trees)
        tt = "radius: $(row.crown_spread_radius)<br>height: $(row.height_n)<br>common name: $(row.commonname)"
        draw!(fig, row.pointgeom; radius=row.crown_spread_radius, color="#71b36b", fill=true, stroke=false, fill_opacity=0.8, tooltip=tt)
    end
    draw!(fig, buildings.geometry)
    write("shadow_map.html", repr("text/html", fig))
    #draw!(fig, shadows.geometry; fill_opacity=0.5, color=:black)
end
g_osm_bike_small, g_bike_small = shadow_graph_from_file(joinpath(datapath, "clifton/test_clifton_bike.json"); network_type=:bike)
#g_osm_bike, g_bike = shadow_graph_from_file(joinpath(datapath, "nottingham_bike_full.json"); network_type=:bike)
correct_centerlines!(g_bike_small, buildings)
add_shadow_intervals!(g_bike_small, shadows)
export_graph_to_csv("test", g_bike; remove_internal_data=false)


g_osm_drive, g_drive = shadow_graph_from_file(joinpath(datapath, "test_clifton.json"))

using Plots
path = get_prop(g_bike_small, 1676, 1677, :edgegeom)
shadow = get_prop(g_bike, 1676, 1677, :shadowgeom)
shadow_parts = get_prop(g_bike, 1676, 1677, :shadowpartgeom)


plot!(path)
for line in getgeom(shadow)
    plot!(line, lw=13, alpha=0.4)
end
for line in getgeom(shadow_parts)
    plot!(line, lw=8)
end
plot!(size=(2000, 2000))

get_prop(g_bike, :offset_dir)

vertices(g_bike)

begin
    fig = draw(g_base, :vertices;
        figure_params=Dict(:location => (52.904, -1.18), :zoom_start => 14),
        radius=3,
        color=:red)
    draw!(fig, g_bike, :edges; color=:red, opacity=0.5, weight=5)
    draw!(fig, g_drive, :vertices; radius=1.5, color=:black, opacity=0.6)
    draw!(fig, g_drive, :edges; color=:black, opacity=0.3)
end

begin
    _, g_rtree = shadow_graph_from_file(joinpath(datapath, "clifton/test_clifton_bike.json"); network_type=:bike)
    correct_centerlines!(g_rtree, buildings)
end
lines_rtree = add_shadow_intervals!(g_rtree, shadows)

lines_normal
lines_rtree

using Plots
scatter(lines_normal.sl - lines_rtree.sl)

get_prop(g_base, :crs)

@benchmark add_shadow_intervals!(g, $shadows) seconds = 30 setup = (g = deepcopy($g_base))
@benchmark add_shadow_intervals!(g, $shadows) seconds = 120 setup = (g = deepcopy($g_base))

print(@report_opt add_shadow_intervals!(g_base, shadows))
@code_warntype add_shadow_intervals!(g_base, shadows)
@time add_shadow_intervals!(g, shadows);
@profview add_shadow_intervals!(g, shadows)
@report_opt DataFrame()

function test()
    df = DataFrame()
    push!(df, Dict(:a => 4))
    return df
end

@code_warntype test()

scatter(2lines_normal.spl .- lines_reconstructed.spl)

describe(lines_normal)
describe(old_lines)
begin
    p = plot()
    plot!(ArchGDAL.buffer(lines_normal, 1e-8, 1))
    for i in getgeom(lines_normal)
        plot!(p, i, lw=6, alpha=0.4, xlims=(-0.1, 0.0))
    end
    plot!()
end
g_plot = g_bike_small
begin
    fig = draw(shadows.geometry;
        figure_params=Dict(:location => (52.904, -1.18), :zoom_start => 14),
        fill_opacity=0.5,
        color=:black)
    draw!(fig, buildings.geometry)
    draw!(fig, g_plot, :vertices)
    draw!(fig, g_plot, :edgegeom)
    draw!(fig, g_plot, :shadowgeom)
    draw!(fig, g_plot, :edges)
end


ngeom(get_prop(g, 8, 717, :shadowgeom))

plot()
for i in getgeom(get_prop(g, 8, 717, :shadowgeom))
    display(plot!(i, lw=6, alpha=0.4))
end


#POLYGON ((-1.18871433326168 52.9075475452531,-1.18874327518357 52.9074308810968,-1.18885830894734 52.9074415541226,-1.18882863220356 52.9075577642415,-1.18871433326168 52.9075475452531))
#Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs
#he terminal process "/Users/henrikwolf/.julia/juliaup/julia-1.8.0+0.aarch64/bin/julia '-i', '--banner=no', '--project=/Users/henrikwolf/Desktop/Masterarbeit/packages/MinistryOfCoolWalks.jl', '/Users/henrikwolf/.vscode/extensions/julialang.language-julia-1.37.2/scripts/terminalserver/terminalserver.jl', '/var/folders/bt/2m4mg981285dt0_6mz596v000000gn/T/vsc-jl-repl-41d504be-790b-4584-b0a2-560623d9b073', '/var/folders/bt/2m4mg981285dt0_6mz596v000000gn/T/vsc-jl-cr-b25b8e51-7f5b-4990-82dc-e99e23d7ea81', 'USE_REVISE=true', 'USE_PLOTPANE=true', 'USE_PROGRESS=true', 'ENABLE_SHELL_INTEGRATION=true', 'DEBUG_MODE=false'" terminated with exit code: 139.


tree = RTree{Float64,2}(ArchGDAL.IGeometry)

p1 = first(shadows.geometry)
bb = ArchGDAL.boundingbox(p1)
br = getgeom(bb, 1)

ArchGDAL.boundingbox(br)

geomtrait(br)
getgeom(br)

for geom in shadows.geometry
    insert!(tree, SpatialIndexing.Rect(MinistryOfCoolWalks.get_bbox_min_max(geom)...), geom)
end

tree

MinistryOfCoolWalks.get_bbox_min_max(p1)


e = GeoInterface.extent(br)
values(e)

@code_warntype ArchGDAL.createlinestring()

using SpatialIndexing

typeof(intersection)

eltype(intersection)

eltype(intersection)

fiter = iterate(intersection)

function treeiteration()
    seq_tree = RTree{Float64,2}(Int, String, leaf_capacity=20, branch_capacity=20)
    for i in 1:100
        x = rand()
        y = rand()
        insert!(seq_tree, SpatialIndexing.Rect((x, y), (x, y)), i, string(i))
    end
    intersection = SpatialIndexing.intersects_with(seq_tree, SpatialIndexing.Rect((0, 0), (0.4, 0.4)))
    for i in intersection
        typeof(i)
    end
end

@code_warntype _iterate(intersection, fiter[2])

l1 = ArchGDAL.createlinestring(collect(0.0:5.0), fill(0, 5))

l2 = ArchGDAL.createlinestring([4.2, 6.9, 7.3], [0.0, 0.0, 3.5])
ml = ArchGDAL.createmultilinestring()
ArchGDAL.addgeom!(ml, l1)
ArchGDAL.addgeom!(ml, l2)
using Plots
plot(l1)
plot!(l2)
using GeoInterface

@code_warntype MinistryOfCoolWalks.rebuild_lines(ml, 0.0003)
@code_warntype MinistryOfCoolWalks.rebuild_lines([l1, l2], 0.0003)

tree84 = build_rtree(shadows2.geometry);

tree84.root.mbr.low
tree84.root.mbr.high

_, g_rtree = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
lines_rtree = add_shadow_intervals!(g_rtree, shadows);

ext = GeoInterface.extent(shadows2.geometry[1])
collect(zip(values(ext)...))

lines_rtree.root.mbr.low
fieldnames(SpatialIndexing.Rect)
function draw_tree!(p, tree::RTree)
    draw_tree!(p, tree.root)
end

function draw_tree!(p, branch::SpatialIndexing.Branch)
    low = branch.mbr


end
rect_from_geom(ls)

rect_from_geom(ls)

ls = get_prop(g_rtree, 8, 717, :edgegeom)
@code_warntype rect_from_geom(ls)

x, y = zip((1, 2), (3, 4))

x
y

mat = falses(10, 10)
for j in 1:10
    for i in 1:10
        if j == i
            mat[i, j] = false
        elseif j < i
            mat[i, j] = rand() < 0.8
        else
            mat[i, j] = mat[j, i]
        end
    end
end
mat

all_tag_dicts = [i.tags for i in values(g_osm_bike.ways)]

all_tag_bike = [get_prop(g_bike, edge, :tags) for edge in edges(g_bike) if has_prop(g_bike, edge, :tags)]
parse_dir_bike = [get_prop(g_bike, edge, :parsing_direction) for edge in edges(g_bike) if has_prop(g_bike, edge, :parsing_direction)]
begin
    df = DataFrame()
    for d in all_tag_bike
        push!(df, d; cols=:union)
    end
    df.parse_dir = parse_dir_bike
    df.offset_dist = [MinistryOfCoolWalks.guess_offset_distance(i...) for i in zip(all_tag_bike, parse_dir_bike)]
    select!(df, ["lanes", "lanes:forward", "lanes:backward", "lanes:both_ways", "highway", "width", "oneway", "parse_dir", "offset_dist"])
end

names(df)


all_tag_bike[1]
MinistryOfCoolWalks.guess_offset_distance(all_tag_bike[1])




using DataFrames
df = DataFrame()
df.lanesfwd = [i["lanes:forward"] for (a, i) in all_tag_bike]
df.lanesbwd = [i["lanes:backward"] for (a, i) in all_tag_bike]
df.lanes = [i["lanes"] for (a, i) in all_tag_bike]
df.id_fwd = [a for (a, i) in all_tag_bike]
df.id_bwd = [a for (a, i) in all_tag_bike]
df.id_fwd = [a for (a, i) in all_tag_bike]


all_keys = vcat(collect.(keys.(all_tag_bike))...)

keycount = [(i, count(==(i), all_keys)) for i in unique(all_keys)]

mapreduce(x -> haskey(x, "highway"), (x, y) -> x + y, all_tag_dicts; init=0)


tags = Set(vcat(collect.(keys.(all_tag_dicts))...))

used_values = Dict(tag => collect(Set(get(d, tag, "") for d in all_tag_dicts if haskey(d, tag))) for tag in tags)

used_values["highway"]


MinistryOfCoolWalks.get_rotational_direction(g_bike)


osm_broken, g_broken_lolipop = shadow_graph_from_download(:bbox; network_type=:bike, minlat=52.9436100, minlon=-1.1888500, maxlat=52.9464900, maxlon=-1.1830900)
set_prop!(g_broken_lolipop, :offset_dir, -1)
correct_centerlines!(g_broken_lolipop, buildings)

ngeom(get_prop(g_broken_lolipop, 25, 46, :edgegeom))

nodes = [3, 46, 77, 21, 25, 41, 51, 55]
nodes_second = [46, 25, 41]
begin
    n = nodes#_second
    plot()
    for i in n
        #plot!(get_prop(g_broken_lolipop, i, :pointgeom))
        for j in n
            if has_edge(g_broken_lolipop, i, j) && has_prop(g_broken_lolipop, i, j, :edgegeom)
                line = get_prop(g_broken_lolipop, i, j, :edgegeom)
                plot!(line, c=101i + 13j, lw=10, alpha=0.5, label="$i=>$j")
                plot!(ArchGDAL.pointalongline(line, ArchGDAL.geomlength(line)), c=101i + 13j)
            end
        end
    end
    plot!(ratio=1, size=(1000, 1000))
end

has_edge

begin
    fig = draw(g_broken_lolipop, :vertices;
        figure_params=Dict(:location => (52.904, -1.18), :zoom_start => 14),
        fill_opacity=0.5,
        color=:black)
    draw!(fig, g_broken_lolipop, :edgegeom)
    draw!(fig, g_broken_lolipop, :shadowgeom)
    draw!(fig, g_broken_lolipop, :edges)
end

ShadowGraphs.is_lolipop_node(g_osm_bike, 1595531385)

way_id = g_osm_bike.node_to_way[6877149067]
way = osm_broken.ways[way_id]
nodes = way.nodes


ShadowGraphs.is_lolipop_node(g_osm_bike, 323231177)

LinRange(0, 2π, 9)[1:end-1]


n = 8
angles = LinRange(0, 2π, n + 1)
x_plane = cos.(angles)

x_plane' .* [1, 2, 3]

ring(center_hex, 0) |> collect

hex = HexagonCubic(0, -2, 3)
center_hex = HexagonCubic(0, 0, 0)
neighbor(hex, 7)
cube_linedraw(hex, hex2)
it = hexagons_within(1, hex)

hex2, _ = iterate(it)
ring(1) |> length

function plot_hex!(ax, hex, r=1; kwargs...)
    points = Hexagons.vertices(hex, r, r, 0, 0) |> collect .|> Tuple
    plot!(ax, [points; points[1]]; label="", kwargs...)
end

Hexagons.center.(ring(4))
vertices(center_hex) |> first
begin
    p1 = plot(framestyle=:box, ratio=1)
    # foreach(h -> plot_hex!(p1, h, c=1), neighbors())
    plot_hex!(p1, center_hex, lw=5)
    foreach(h -> plot_hex!(p1, h, c=2), ring(2, center_hex))
    state = 1
    theta = 2 * pi / 6 * (state - 0.5)
    x = 1
    y = 1
    vline!([x * cos(theta)])
    hline!([y * sin(theta), 1, 0.5])
    scatter!(vertices(center_hex) |> first)
    #scatter!(p1, Hexagons.center.(ring(2)))

    # foreach(h -> plot_hex!(p1, h, c=4), hexagons_within(hex, 3))

    #foreach(h -> plot_hex!(p1, h, c=1), ring(2))
    #foreach(h -> plot_hex!(p1, h, c=2), ring(2, hex))
    #scatter!(p1, Hexagons.center.(ring(2), 1, 1, 0, 0))
    p1
end

length()

cube_round(0, 0)
r = 0.0002
test_b = buildings.geometry[3346]
box = ArchGDAL.boundingbox(test_b)
hexes = hexagonify(test_b, r, buffer=false)
hexes[1]

hexpolys = hexes2polys(hexes, r)


buffered = MinistryOfCoolWalks.hexgrid_buffer(hexes)
neighbors

begin
    #plot!(p2, box)
    p2 = plot(framestyle=:box, ratio=1)
    plot!(p2, test_b)
    foreach(p -> plot!(p2, p, lw=5, c=:black), getgeom(test_b))
    foreach(h -> plot_hex!(p2, h, r, c=3, lw=2), buffered)
    foreach(h -> plot_hex!(p2, h, r, c=2, lw=3), hexes)
    plot!(p2, hexpolys)
    plot!(ArchGDAL.centroid(test_b), size=(800, 800))
end

g = shadow_graph_from_file(joinpath(datapath, "clifton/test_clifton_bike.json"); network_type=:bike)

buildings

r2 = 0.001
graph_hexes = hexagonify(g, r2, buffer=2)
building_hexes = hexagonify(buildings.geometry, r2)
graph_hexes_poly = hexes2polys(graph_hexes, r2)
building_hexes_poly = hexes2polys(building_hexes, r2)


all_points = ArchGDAL.createmultipoint()
foreach(Graphs.vertices(g)) do v
    ArchGDAL.addgeom!(all_points, get_prop(g, v, :pointgeom))
end

625 + 105 + 111


foldl(1:0, init=graph_hexes) do f, _
    [f; MinistryOfCoolWalks.hexgrid_buffer(f)]
end

buffered


begin
    p3 = plot(framestyle=:box, ratio=1)
    plot!(p3, graph_hexes_poly, c=:grey)
    plot!(p3, building_hexes_poly, c=:blue)
    foreach(h -> plot_hex!(p3, h, r2, c=2, lw=2), graph_hexes)
    for e in edges(g)
        if has_prop(g, e, :edgegeom)
            # plot!(p3, get_prop(g, e, :edgegeom), c=1, lw=2)
        end
    end
    plot!(p3, all_points, c=1, ms=2, size=(800, 800))
    p3
end




# Base.:^(f::Function, i::Int) = i == 0 ? identity : i == 1 ? f : x -> f((f^(i - 1))(x))

next_fibo(x) = [x; x[end-1] + x[end]]

(next_fibo^10)([1, 1])

mycoll = ArchGDAL.creategeomcollection()

for v in Graphs.vertices(g)
    ArchGDAL.addgeom!(mycoll, get_prop(g, v, :pointgeom))
end

for e in Graphs.edges(g)
    try
        ArchGDAL.addgeom!(mycoll, get_prop(g, e, :edgegeom))
    catch
    end
end

getgeom(mycoll) .|> typeof |> Set

plot!(ArchGDAL.convexhull(mycoll))

plot(mycoll)




using CoolWalksUtils

hextree = build_rtree(building_hexes_poly);

inter = intersects_with(hextree, rect_from_geom(buildings.geometry[1])) |> collect

