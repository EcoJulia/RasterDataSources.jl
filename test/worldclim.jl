module SSLTestWorldClim
using SimpleSDMDataSources
using Test

download_raster(WorldClim, BioClim; layer=2, resolution=10.0)

end
