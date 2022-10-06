using MinistryOfCoolWalks
FoliumMap()

path = "Desktop/Masterarbeit/data/Nottingham/Nottingham.shp"
using ShadowGraphs
using CompositeBuildings
buildings = load_british_shapefiles(joinpath([homedir(), path]); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.6])
m = polygons(shadows.geometry; figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14))
polygons!(m, buildings.geometry)