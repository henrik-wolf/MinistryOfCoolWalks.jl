# Routing
## Introduction
It might be interesting to look shortest paths in out network, using different weights for each edge, based on the length in shade and sun, as well as an external parameter, which essentially weights the length of sunny parts against the length of shaded parts along every edge. Therefore, we introduce our own `Real` subtype, together with a `MetaGraphs.MetaWeights` based Weight-Matrix, which should just work in every `Graphs.jl` algorithm, which takes a Weight Matrix.

## `ShadowWeight` and conditions on addition and comparison
To calculate shortest paths, we need a non negative edge weight, a less-than and an addition operation with a (or possibly multiple) `zero` elements.

we use:

`felt_length(w) = w.shade + w.a * sun`

and

`real_length(w) = w.shade + w.sun`

Since we want to be able to reconstruct the `real_length` from the number `w` which has been used in the shortest path with the `felt_length` function, we additionally need the addition with zero to be invariant under both length operations (this needs to hold for every operation you might want to do on the results from routing with a custom `felt_length`). That is:

`felt_length(w + zero) == felt_length(w) => real_length(w + zero) == real_length(w)`

we archieve this by constraining `a in (0.0, Inf)`, rather than `a in [0.0, Inf)`. In this way, a `zero` is of length 0 under both operations.

Our zero element takes the form of `ShadowWeight(a, 0.0, 0.0)` with an arbitrary `a` as constrained above.


## API

```@index
Pages = ["Routing.md"]
```

```@autodocs
Modules = [MinistryOfCoolWalks]
Pages = ["Routing.jl"]
```