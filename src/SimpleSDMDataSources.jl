module SimpleSDMDataSources

# Load the dependencies for this package
using ArchGDAL
using HTTP
using ZipFile

include("src/assets_path.jl")

abstract struct SDMDataSource end
abstract struct SDMDataSet end

# List of data sources
struct WorldClim <: SDMDataSource end
struct CHELSA <: SDMDataSource end
struct EarthEnv <: SDMDataSource end

# List of data sets
struct BioClim <: SDMDataSet end
struct LandCover <: SDMDataSet end

include("src/worldclim/bioclim.jl")

export download_raster

end # module
