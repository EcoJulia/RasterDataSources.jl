module SimpleSDMDataSources

# Load the dependencies for this package
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
struct HabitatHeterogeneity <: SDMDataSet end

export BioClim, LandCover, HabitatHeterogeneity

# Create a path for the various assets
include("assets_path.jl")

# Download the files if they don't exist
include("download.jl")

# Download raster data
include("worldclim/bioclim.jl")
include("chelsa/bioclim.jl")
include("earthenv/landcover.jl")
include("earthenv/habitatheterogeneity.jl")

export download_raster

end # module
