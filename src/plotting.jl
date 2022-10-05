struct FoliumMap
    obj::PyObject
end
function FoliumMap(;kwargs...)
    if !haskey(kwargs, :location)
        # this might be very useless...
        map = flm.Map(;location=[0.0, 0.0], kwargs...)
    else
        map = flm.Map(;kwargs...)
    end
    return FoliumMap(map)
end


# for nice plot in VS Codes
function Base.show(io::IO, ::MIME"juliavscode/html", map::FoliumMap)
    write(io, repr("text/html", map.obj))
end