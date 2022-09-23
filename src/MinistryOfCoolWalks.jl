module MinistryOfCoolWalks
    using Dates
    using ArchGDAL
    using GeoInterface
    using GeoDataFrames
    using DataFrames

    export sunposition
    include("SunPosition.jl")

    export cast_shadow
    include("ShadowCasting.jl")

    const projstring = "+proj=tmerc +lon_0=-1 +lat_0=53"
end
