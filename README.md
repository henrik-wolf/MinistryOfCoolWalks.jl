# MinistryOfCoolWalks.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://SuperGrobi.github.io/MinistryOfCoolWalks.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://SuperGrobi.github.io/MinistryOfCoolWalks.jl/dev/)
[![Build Status](https://github.com/SuperGrobi/MinistryOfCoolWalks.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/SuperGrobi/MinistryOfCoolWalks.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

this is the heart of the whole CoolWalks operation. Here you find all code related to the interaction of Buildings and Street Networks (Trees as well, but that is basically the same).

All of this is quite britle and lacks solid testing. In the future, I will do somewhat substantial cleanup to polish the API that seems to emerge here.

# Related repos
The rest of the relevant code for graph, building and tree loading is spread pretty wide and thin across multiple other packages. If you are interested in these, please refer to:
- [ShadowGraphs.jl](https://github.com/SuperGrobi/ShadowGraphs.jl) (Loading of OSM Data and processing it into a `MetaDiGraph`, and all kinds of functions to work with the edge geometry)
- [CompositeBuildings.jl](https://github.com/SuperGrobi/CompositeBuildings.jl) (Code to load and preprocess the various building datasets used in this study, and shadow casting)
- [TreeLoaders.jl](https://github.com/SuperGrobi/TreeLoaders.jl) (Code to load and preprocess the various tree datasets not (yet) used in this study, and shadow casting)
- [Folium.jl](https://github.com/SuperGrobi/Folium.jl) (My own hacked together wrapper around `Folium`, the python wrapper around `Leaflet.js`. Yeah... I know... this is not how it should be done, but it is surprisingly fast and interactive and seems to work quite well. In the future, we should direct this effort towards [`Leaflet.jl`](https://github.com/JuliaGeo/Leaflet.jl))
- [CoolWalksUtils.jl](https://github.com/SuperGrobi/CoolWalksUtils.jl) (Here lives all the small stuff I need upstream of all my helper packages. Also owns all the functions need to add methods to in the other helper packages above)

# alternative project title
Since we are probably not going to use temperature data to inform our decisions, we might need to change the name of this project to something more ... appropriate... below I compile a list of alternative titles.

- ShadedWalks
- VampireSightSeeing
- 50 shades of walk (well... better would be 2 shades of walk. But that is... very far of.)
- shade happens.
- routing in the shade (Adele)

these work well if we actually call the "shadow importance" the "vampire factor":
- twilight (just twilight)
- what we do in the shadows (it's walking.)
- walk, we do in the shadows


