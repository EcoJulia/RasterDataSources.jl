module RasterDataSources

using Dates,
      HTTP,
      ZipFile,
      URIs

abstract type RasterDataSource end
abstract type RasterDataSet end

struct BioClim <: RasterDataSet end
struct Climate <: RasterDataSet end
struct Weather <: RasterDataSet end
struct LandCover <: RasterDataSet end
struct HabitatHeterogeneity <: RasterDataSet end

export WorldClim, CHELSA, EarthEnv, AWAP, ALWB

export BioClim, Climate, Weather, LandCover, HabitatHeterogeneity

export getraster

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

end # module
