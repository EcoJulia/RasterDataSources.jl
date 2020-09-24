module SimpleSDMDataSources

# Load the dependencies for this package
using HTTP,
      ZipFile,
      Dates

# Abstract types for the download
abstract type SDMDataSource end
abstract type SDMDataSet end

# List of data sources

struct WorldClim{X} <: SDMDataSource end
struct CHELSA <: SDMDataSource end
struct EarthEnv <: SDMDataSource end

export WorldClim, CHELSA, EarthEnv, AWAP, ALWB

# List of data sets
struct Weather <: SDMDataSet end
struct BioClim <: SDMDataSet end
struct LandCover <: SDMDataSet end
struct HabitatHeterogeneity <: SDMDataSet end

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
include("earthenv/landcover.jl")
include("earthenv/habitatheterogeneity.jl")
include("awap/awap.jl")
include("alwb/alwb.jl")

export download_raster

end # module
