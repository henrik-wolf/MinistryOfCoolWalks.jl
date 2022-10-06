##############################################
## FOLIUM TAKES ALL COORDINATES AS LAT, LON ##
##############################################
struct FoliumMap
    obj::PyObject
end
function FoliumMap(;kwargs...)
    if !haskey(kwargs, :location)
        # this might be very useless...
        flmmap = flm.Map(;location=[0.0, 0.0], kwargs...)
    else
        flmmap = flm.Map(;kwargs...)
    end
    return FoliumMap(flmmap)
end

# for nice plot in VS Codes
function Base.show(io::IO, ::MIME"juliavscode/html", flmmap::FoliumMap)
    write(io, repr("text/html", flmmap.obj))
end

# for nice plots everywhere else
function Base.show(io::IO, mime::MIME"text/html", flmmap::FoliumMap)
    show(io, mime, flmmap.obj)
end

############  CIRLCES  ################
function circles!(flmmap, points; kwargs...)
    @nospecialize
    for point in points
        flm.Circle(point; kwargs...).add_to(flmmap.obj)
    end
    return flmmap
end

function circles!(flmmap, lon, lat; kwargs...)
    @nospecialize
    return circles!(flmmap, zip(lat, lon); kwargs...)
end

function circles(points; figure_params=Dict(), kwargs...)
    @nospecialize  # TODO: test the impact on speed. (Since we are calling python, this will probably be slow nonetheless...)
    flmmap = FoliumMap(; figure_params...)
    return circles!(flmmap, points; kwargs...)
end

function circles(lons, lats; figure_params=Dict(), kwargs...)
    @nospecialize  # TODO: test the impact on speed.
    return circles(zip(lats, lons); figure_params=figure_params, kwargs...)
end

############  CIRCLEMARKERS ###############
function circleMarkers!(flmmap, points; kwargs...)
    @nospecialize
    for point in points
        flm.CircleMarker(point; kwargs...).add_to(flmmap.obj)
    end
    return flmmap
end

function circleMarkers!(flmmap, lon, lat; kwargs...)
    @nospecialize
    return circleMarkers!(flmmap, zip(lat, lon); kwargs...)
end

function circleMarkers(points; figure_params=Dict(), kwargs...)
    @nospecialize  # TODO: test the impact on speed. (Since we are calling python, this will probably be slow nonetheless...)
    flmmap = FoliumMap(; figure_params...)
    return circleMarkers!(flmmap, points; kwargs...)
end

function circleMarkers(lons, lats; figure_params=Dict(), kwargs...)
    @nospecialize  # TODO: test the impact on speed.
    return circleMarkers(zip(lats, lons); figure_params=figure_params, kwargs...)
end

######## POLYGONS #########

function polygons!(flmmap, polys; kwargs...)
    for poly in polys
        outer_poly = getgeom(poly, 1)
        points = [(getcoord(point, 2), getcoord(point, 1)) for point in getgeom(outer_poly)]
        flm.Polygon(points; kwargs...).add_to(flmmap.obj)
    end
    return flmmap
end

function polygons(polys; figure_params=Dict(), kwargs...)
    flmmap = FoliumMap(; figure_params...)
    return polygons!(flmmap, polys; kwargs...)
end

########## POLYLINES  ##############

# single lines, called with lon and lat coords
function polyline!(flmmap, lon, lat; kwargs...)
    flm.PolyLine(zip(lat, lon); kwargs...).add_to(flmmap.obj)
    return flmmap
end

function polyline(lon, lat; figure_params=Dict(), kwargs...)
    flmmap = FoliumMap(; figure_params...)
    return polyline!(flmmap, lon, lat; kwargs...)
end

# single lines, called with geo interface compatible geometry
function polyline!(flmmap, polyline; kwargs...)
    points = [(getcoord(point, 2), getcoord(point, 1)) for point in getgeom(polyline)]
    flm.PolyLine(points; kwargs...).add_to(flmmap.obj)
    return flmmap
end

function polyline(polyline; figure_params=Dict(), kwargs...)
    flmmap = FoliumMap(; figure_params...)
    return polyline!(flmmap, polyline; kwargs...)
end

# list of lines with geo interface compatible geometry
function polylines!(flmmap, polylines; kwargs...)
    for line in polylines
        polyline!(flmmap, line; kwargs)
    end
    return flmmap
end

function polylines(polylines; figure_params=Dict(), kwargs...)
    flmmap = FoliumMap(; figure_params...)
    return polylines!(flmmap, polylines; kwargs...)
end

######## OTHER ############

# this takes a list like: [(minlat, minlon), (maxlat, maxlon)]
fit_bounds!(flmmap, bounds) = flmmap.obj.fit_bounds(bounds)


####### GRAPH PLOTTING #######
function get_vert_coords(g)
    lons = [get_prop(g, i, :lon) for i in vertices(g)]
    lats = [get_prop(g, i, :lat) for i in vertices(g)]
    return lons, lats
end

# graph nodes
function graph_node_circles!(flmmap, g; kwargs...)
    lons, lats = get_vert_coords(g)
    return circles!(flmmap, lons, lats; kwargs...)
end

function graph_node_circles(g; figure_params=Dict(), kwargs...)
    flmmap = FoliumMap(; figure_params...) 
    return graph_node_circles!(flmmap, g; kwargs...)
end

function graph_node_circleMarkers!(flmmap, g; kwargs...)
    lons, lats = get_vert_coords(g)
    return circleMarkers!(flmmap, lons, lats; kwargs...)
end

function graph_node_circleMarkers(g; figure_params=Dict(), kwargs...)
    flmmap = FoliumMap(; figure_params...) 
    return graph_node_circleMarkers!(flmmap, g; kwargs...)
end

# graph edges
function graph_edges!(flmmap, g; kwargs...)
    for edge in edges(g)
        sla = get_prop(g, src(edge), :lat)
        slo = get_prop(g, src(edge), :lon)
        dla = get_prop(g, dst(edge), :lat)
        dlo = get_prop(g, dst(edge), :lon)
        polyline!(flmmap, [slo, dlo], [sla, dla]; kwargs...)
    end
    return flmmap
end

function graph_edges(g; figure_params=Dict(), kwargs...)
    flmmap = FoliumMap(; figure_params...)
    return graph_edges!(flmmap, g; kwargs...)
end

# graph edge geometry

function graph_edge_geometries!(flmmap, g; kwargs...)
    for edge in edges(g)
        !has_prop(g, edge, :geolinestring) && continue  # skip helper edges
        linestring = get_prop(g, edge, :geolinestring)
        polyline!(flmmap, linestring; kwargs...)
    end
    return flmmap
end

function graph_edge_geometries(g; figure_params=Dict(), kwargs...)
    flmmap = FoliumMap(; figure_params...)
    return graph_edge_geometries!(flmmap, g; kwargs...)
end