# Centerline Correction
## Introduction
The ways as given by OSM denote, by convention, the center of the streets, which usually is not the place where we see pedestrians walking.
To get a more accurate picture of how much shadow there is on the sidewalks, we need to offset the ways to where pedestrians would usually walk.
This procedure, including estimating the width of the street is handled here.

## API

```@index
Pages = ["CenterlineCorrection.md"]
```

```@autodocs
Modules = [MinistryOfCoolWalks]
Pages = ["CenterlineCorrection.jl"]
```