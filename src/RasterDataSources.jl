module RasterDataSources
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end RasterDataSources

using Dates,
      GeoData,
      HTTP,
      Requires,
      URIs,
      ZipFile

abstract type RasterDataSource end
abstract type RasterDataSet end

struct BioClim <: RasterDataSet end
struct Climate <: RasterDataSet end
struct Weather <: RasterDataSet end
struct LandCover <: RasterDataSet end
struct HabitatHeterogeneity <: RasterDataSet end

export WorldClim, CHELSA, EarthEnv, AWAP, ALWB

export BioClim, Climate, Weather, LandCover, HabitatHeterogeneity

export Values, Deciles

export getraster

export geoarray, stack, series

include("shared.jl")
include("worldclim/shared.jl")
include("worldclim/bioclim.jl")
include("worldclim/climate.jl")
include("worldclim/weather.jl")
include("chelsa/bioclim.jl")
include("earthenv/shared.jl")
include("earthenv/landcover.jl")
include("earthenv/habitatheterogeneity.jl")
include("awap/awap.jl")
include("alwb/alwb.jl")

function __init__()
    @require GeoData="9b6fcbb8-86d6-11e9-1ce7-23a6bb139a78" begin
        include("geodata.jl")
    end
end

end # module
