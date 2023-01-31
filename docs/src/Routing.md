# Routing
## Introduction
It might be interesting to look shortest paths in out network, using different weights for each edge, based on the length in shade and sun, as well as an external parameter, which essentially weights the length of sunny parts against the length of shaded parts along every edge. Therefore, we introduce our own `Real` subtype, together with a `MetaGraphs.MetaWeights` based Weight-Matrix, which should just work in every `Graphs.jl` algorithm, which takes a Weight Matrix.

## API

```@index
Pages = ["Routing.md"]
```

```@autodocs
Modules = [MinistryOfCoolWalks]
Pages = ["Routing.jl"]
```