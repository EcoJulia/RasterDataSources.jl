module RasterDataSources

# Load the dependencies for this package
using HTTP,
      ZipFile,
      Dates

# Abstract types for the download
abstract type RasterDataSource end
abstract type RasterDataSet end

# List of data sources

struct WorldClim{X} <: RasterDataSource end
struct CHELSA{X} <: RasterDataSource end
struct EarthEnv{X} <: RasterDataSource end

export WorldClim, CHELSA, EarthEnv, AWAP, ALWB

# List of data sets
struct Weather <: RasterDataSet end
struct BioClim <: RasterDataSet end
struct LandCover <: RasterDataSet end
struct HabitatHeterogeneity <: RasterDataSet end

export BioClim, Weather, LandCover, HabitatHeterogeneity

# Using types to specify layers makes sense in some contexts
# These are exported for AWAP, but are experimental
export Temperature, VapourPressure, Solar, Rainfall, H09, H15, MinAve, MaxAve

export download_raster, rasterpath

# Create a path for the various assets
include("assets_path.jl")

# Download the files if they don't exist
include("download.jl")

# Download raster data
include("worldclim/shared.jl")
include("worldclim/bioclim.jl")
include("worldclim/weather.jl")
include("chelsa/bioclim.jl")
include("earthenv/shared.jl")
include("earthenv/landcover.jl")
include("earthenv/habitatheterogeneity.jl")
include("awap/awap.jl")
include("alwb/alwb.jl")

export download_raster

end # module
