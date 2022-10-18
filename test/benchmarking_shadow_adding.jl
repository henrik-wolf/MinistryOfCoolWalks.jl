
datapath = joinpath(homedir(), "Desktop/Masterarbeit/data/Nottingham/")
buildings = load_british_shapefiles(joinpath(datapath, "Nottingham.shp"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.4])


options = [(operation, flag) 
    for operation in (add_shadow_intervals!, add_shadow_intervals_rtree!, add_shadow_intervals_linear!) 
    for flag in (:reconstruct, :buffer)]

timing_data = DataFrame()
for (operation, flag) in options
    _, g = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
    t = @timed shadow_df = operation(g, shadows; method=flag)
    t = Dict(pairs(t))
    delete!(t, :value)
    t[:operation] = repr(operation)
    t[:flag] = flag
    push!(timing_data, t; cols=:union)
end