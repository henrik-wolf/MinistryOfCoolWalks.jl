# MinistryOfCoolWalks.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://SuperGrobi.github.io/MinistryOfCoolWalks.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://SuperGrobi.github.io/MinistryOfCoolWalks.jl/dev/)
[![Build Status](https://github.com/SuperGrobi/MinistryOfCoolWalks.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/SuperGrobi/MinistryOfCoolWalks.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

Central repository of the `CoolWalks` project. Here we combine buildings, streets and trees to find the CoolWalkability of cities.

# Related repos
The relevant code for graph, building and tree loading is spread across multiple other packages. If you are interested in these, please refer to:
- [ShadowGraphs.jl](https://github.com/SuperGrobi/ShadowGraphs.jl) (Loading of OSM Data and processing it into a `MetaDiGraph`, and all kinds of functions to work with the edge geometry)
- [CompositeBuildings.jl](https://github.com/SuperGrobi/CompositeBuildings.jl) (Code to load and preprocess the various building datasets used in this study, and shadow casting)
- [TreeLoaders.jl](https://github.com/SuperGrobi/TreeLoaders.jl) (Code to load and preprocess the various tree datasets not (yet) used in this study, and shadow casting)
- [Folium.jl](https://github.com/SuperGrobi/Folium.jl) (Our hacked together wrapper around `Folium`, the python wrapper around `Leaflet.js`. (It is surprisingly fast and interactive and seems to work quite well. In the future, we should direct this effort towards [`Leaflet.jl`](https://github.com/JuliaGeo/Leaflet.jl)))
- [CoolWalksUtils.jl](https://github.com/SuperGrobi/CoolWalksUtils.jl) (Utilities used throughout the above packages. Owns many of the functions to which we add specialisations in the other packages.)