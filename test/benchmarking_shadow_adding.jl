using DataFrames
using MinistryOfCoolWalks
using CompositeBuildings
using ShadowGraphs
using CSV
using Plots

datapath = joinpath(homedir(), "Desktop/Masterarbeit/data/Nottingham/")
buildings = load_british_shapefiles(joinpath(datapath, "Nottingham.shp"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.4])

#iterations = [10, 10, 2]
#operations = [add_shadow_intervals!, add_shadow_intervals_rtree!, add_shadow_intervals_linear!]

iterations = [30]
operations = [add_shadow_intervals_rtree!]

options = [(iter, operation, flag) 
    for (iter, operation) in  zip(iterations, operations)
    for flag in (:reconstruct, :buffer)]

    
result_path = joinpath(homedir(), "Desktop/Masterarbeit/packages/MinistryOfCoolWalks.jl/test/add_shadow_benchmark_prepared.csv")
result_path_old = joinpath(homedir(), "Desktop/Masterarbeit/packages/MinistryOfCoolWalks.jl/test/add_shadow_benchmark.csv")

run_benchmark = true
if run_benchmark
    timing_data = DataFrame()
    for (iter, operation, flag) in options
        println(repr(operation), flag)
        for i in 0:iter
            _, g = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
            t = @timed shadow_df = operation(g, shadows; method=flag)
            i == 0 && continue  # warmup
            t = Dict(pairs(t))
            delete!(t, :value)
            t[:i] = i
            t[:operation] = repr(operation)
            t[:flag] = flag
            push!(timing_data, t; cols=:union)
        end
    end
    CSV.write(result_path, timing_data)
else
    timing_data = CSV.read(result_path, DataFrame)
end

timing_data_old = filter(:operation=>op->contains(op, "rtree!"), CSV.read(result_path_old, DataFrame))
timing_data_old.old .= true

timing_data
timing_data.old .= false

append!(timing_data, timing_data_old)

grouped = groupby(full_df, [:old, :flag])
using Statistics
times = combine(grouped, :time=>mean=>:mean, :time=>(x->[extrema(x)])=>[:min, :max], :time=>median=>:median)
using StatsPlots
plot(times)

full_df = vcat(timing_data, timing_data_old)

times


g2 = groupby(filter(:operation=>x->!contains(x, "linear"), times), :flag)

combine(g2, :mean=>(x->maximum(x)/minimum(x))=>:speedup)

p = @df times groupedbar(:mean, group=:old)
plot!(framestyle=:box, ylabel="time [s]", ylims=(0, 3))

times