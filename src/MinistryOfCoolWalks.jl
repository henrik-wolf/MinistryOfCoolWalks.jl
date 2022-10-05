module MinistryOfCoolWalks
    using Dates
    using ArchGDAL
    using GeoInterface
    using GeoDataFrames
    using DataFrames
    using PyCall
    const flm = PyNULL()
    function __init__()
        # weird stuff with importing at runtime. Might switch to pyimport_conda("folium", "folium")
        # for ease of setup.
        copy!(flm, pyimport("folium"))
        nothing
    end

    export sunposition
    include("SunPosition.jl")

    export cast_shadow
    include("ShadowCasting.jl")

    export FoliumMap
    include("plotting.jl")

    # something something debugging...
    const projstring = "+proj=tmerc +lon_0=-1 +lat_0=53"
end