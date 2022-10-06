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
    return circles!(flmmap, zip(lon, lat); kwargs...)
end

function circles(points; figure_params=Dict(), kwargs...)
    @nospecialize  # TODO: test the impact on speed. (Since we are calling python, this will probably be slow nonetheless...)
    flmmap = FoliumMap(; figure_params...)
    return circles!(flmmap, points; kwargs...)
end

function circles(lons, lats; figure_params=Dict(), kwargs...)
    @nospecialize  # TODO: test the impact on speed.
    return circles(zip(lons, lats); figure_params=figure_params, kwargs...)
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
    return circleMarkers!(flmmap, zip(lon, lat); kwargs...)
end

function circleMarkers(points; figure_params=Dict(), kwargs...)
    @nospecialize  # TODO: test the impact on speed. (Since we are calling python, this will probably be slow nonetheless...)
    flmmap = FoliumMap(; figure_params...)
    return circleMarkers!(flmmap, points; kwargs...)
end

function circleMarkers(lons, lats; figure_params=Dict(), kwargs...)
    @nospecialize  # TODO: test the impact on speed.
    return circleMarkers(zip(lons, lats); figure_params=figure_params, kwargs...)
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

function polylines!(flmmap, polylines; kwargs...)
    for line in polylines
        points = [(getgeom(point, 2), getgeom(point, 1)) for point in getgem(line)]
        flm.PolyLine(points; kwargs...).add_to(flmmap.obj)
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