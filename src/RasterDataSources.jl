module RasterDataSources

using Dates,
      HTTP,
      ZipFile,
      URIs

# Abstract types for the download
abstract type RasterDataSource end
abstract type RasterDataSet end

# List of data sets
struct BioClim <: RasterDataSet end
struct Climate <: RasterDataSet end
struct LandCover <: RasterDataSet end
struct HabitatHeterogeneity <: RasterDataSet end
struct Weather <: RasterDataSet end

export WorldClim, CHELSA, EarthEnv, AWAP, ALWB

export BioClim, Climate, Weather, LandCover, HabitatHeterogeneity

# Using types to specify layers makes sense in some contexts
# These are exported for AWAP, but are experimental
export Temperature, VapourPressure, Solar, Rainfall, H09, H15, MinAve, MaxAve

export download_raster, rasterpath

include("assets_path.jl")
include("utils.jl")
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
