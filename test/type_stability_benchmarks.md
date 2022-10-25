# Benchmarks for the shadow intersection algorithm
I am always running:
```julia
using MinistryOfCoolWalks
using ShadowGraphs
using CompositeBuildings
using BenchmarkTools

datapath = joinpath(homedir(), "Desktop/Masterarbeit/data/Nottingham/")
buildings = load_british_shapefiles(joinpath(datapath, "Nottingham.shp"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.4])
_, g_base = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
@benchmark add_shadow_intervals_rtree!(g, $shadows) seconds=40 setup=(g = deepcopy($g_base))
```


## benchmark of add_shadow_intervals_rtree! before any optimisation (surprisingly faster than what I remember)
```
BenchmarkTools.Trial: 22 samples with 1 evaluation.
 Range (min … max):  1.320 s …    2.127 s  ┊ GC (min … max): 3.92% … 15.44%
 Time  (median):     1.351 s               ┊ GC (median):    4.81%
 Time  (mean ± σ):   1.396 s ± 167.007 ms  ┊ GC (mean ± σ):  5.46% ±  2.38%

  ▃█▃▁                                                        
  ████▁▁▄▄▇▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▄ ▁
  1.32 s         Histogram: frequency by time         2.13 s <

 Memory estimate: 619.20 MiB, allocs estimate: 12753497.
```
## after throwing out buffered length estimation and dataframes
```
BenchmarkTools.Trial: 32 samples with 1 evaluation.
 Range (min … max):  1.257 s …   1.313 s  ┊ GC (min … max): 4.58% … 5.47%
 Time  (median):     1.271 s              ┊ GC (median):    4.89%
 Time  (mean ± σ):   1.274 s ± 10.196 ms  ┊ GC (mean ± σ):  4.84% ± 0.35%

    ▃        ▃▃██  ▃█▃  ▃  ▃                                 
  ▇▁█▁▁▇▁▇▇▇▁████▁▁███▁▁█▁▇█▇▁▁▇▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▇ ▁
  1.26 s         Histogram: frequency by time        1.31 s <

 Memory estimate: 618.44 MiB, allocs estimate: 12744900.
```

## After fixing problems in the way I build the R-Tree
BenchmarkTools.Trial: 16 samples with 1 evaluation.
 Range (min … max):  544.607 ms … 856.762 ms  ┊ GC (min … max): 0.00% … 16.95%
 Time  (median):     623.116 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   658.630 ms ± 110.019 ms  ┊ GC (mean ± σ):  5.24% ±  6.97%

          █                                                 ▃    
  ▇▁▇▁▇▁▁▁█▁▇▁▁▇▁▁▇▇▇▁▇▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▇▁▁▁▁▁▁▁█▁▇ ▁
  545 ms           Histogram: frequency by time          857 ms <

 Memory estimate: 44.65 MiB, allocs estimate: 1168353.