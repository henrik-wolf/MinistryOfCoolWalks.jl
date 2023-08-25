# Centerline Correction
## Introduction
When loading shadow graph from OSM data, the street geometry represents, by convention, the center of the streets,
which usually is not the place where we see pedestrians walking. To get a more accurate picture of how much shadow
there is on the sidewalks, we need to offset the ways to where pedestrians would usually walk.
This procedure, including estimating the width of the street is handled here.

## Default values
As the datamodel of OSM allows for a certain variability in completeness of the mapped tags on each street, we need
to assume some sensible default values for the width of streets, as well as for the types of `highways` which denote
the centerline of streets vs pedestrian spaces. We have:

- [`MinistryOfCoolWalks.DEFAULT_LANES_ONEWAY`](@ref)
- [`MinistryOfCoolWalks.HIGHWAYS_OFFSET`](@ref)
- [`MinistryOfCoolWalks.HIGHWAYS_NOT_OFFSET`](@ref)

If you encounter highways in your dataset which are not present, or would like to change the values given, you can
update/add/... them as you need.

## API

```@index
Pages = ["CenterlineCorrection.md"]
```

```@autodocs
Modules = [MinistryOfCoolWalks]
Pages = ["CenterlineCorrection.jl"]
```