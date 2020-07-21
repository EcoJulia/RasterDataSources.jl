module SimpleSDMDataSources

# Load the dependencies for this package
using ArchGDAL
using HTTP
using ZipFile

# Abstract types for the download
abstract type SDMDataSource end
abstract type SDMDataSet end

# List of data sources
struct WorldClim <: SDMDataSource end
struct CHELSA <: SDMDataSource end
struct EarthEnv <: SDMDataSource end

export WorldClim, CHELSA, EarthEnv

# List of data sets
struct BioClim <: SDMDataSet end
struct LandCover <: SDMDataSet end

export BioClim, LandCover

# Create a path for the various assets
include("assets_path.jl")

# Download raster data
include("worldclim/bioclim.jl")
include("earthenv/landcover.jl")

export download_raster

end # module
