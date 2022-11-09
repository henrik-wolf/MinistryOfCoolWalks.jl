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
```
BenchmarkTools.Trial: 48 samples with 1 evaluation.
 Range (min … max):  153.323 ms … 463.462 ms  ┊ GC (min … max): 0.00% … 27.76%
 Time  (median):     171.417 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   200.676 ms ±  79.300 ms  ┊ GC (mean ± σ):  6.06% ±  8.29%

  ▄█▄█ ▃                                                         
  ████▇█▆▁▁▁▆▄▁▁▁▁▁▁▁▁▄▁▁▁▁▁▄▁▁▁▁▁▁▁▁▁▁▄▁▄▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▄▁▁▆ ▁
  153 ms           Histogram: frequency by time          463 ms <

 Memory estimate: 17.30 MiB, allocs estimate: 303478
 ```

# Ok. lets do this in the correct way, with code which actually does what I want.
## before. Neive implementation, O(edges*shadows)
```
BenchmarkTools.Trial: 14 samples with 1 evaluation.
 Range (min … max):  8.426 s …   10.128 s  ┊ GC (min … max): 1.74% … 3.31%
 Time  (median):     8.876 s               ┊ GC (median):    2.40%
 Time  (mean ± σ):   9.006 s ± 457.832 ms  ┊ GC (mean ± σ):  2.48% ± 1.04%

  ▁  ▁  ▁     ▁█▁▁    ▁▁   ▁  ▁              ▁             ▁  
  █▁▁█▁▁█▁▁▁▁▁████▁▁▁▁██▁▁▁█▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
  8.43 s         Histogram: frequency by time         10.1 s <

 Memory estimate: 275.02 MiB, allocs estimate: 17663244.
```

## after. using R-Trees and julia optimisations, mainly type stable, O(edges*ld(shadows))
```
BenchmarkTools.Trial: 139 samples with 1 evaluation.
 Range (min … max):  146.543 ms … 668.627 ms  ┊ GC (min … max): 0.00% … 19.78%
 Time  (median):     168.785 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   197.579 ms ±  82.806 ms  ┊ GC (mean ± σ):  4.68% ±  7.22%

  ▄█▇▅ ▂                                                         
  ███████▅▃▃▄▃▁▃▁▁▃▃▁▃▁▃▁▃▁▃▁▁▁▁▁▃▁▁▁▁▃▁▁▁▁▃▁▁▁▁▁▁▃▃▃▁▁▁▁▁▁▁▁▁▃ ▃
  147 ms           Histogram: frequency by time          527 ms <

 Memory estimate: 15.31 MiB, allocs estimate: 250015.
```
 ## 50 times speedup?