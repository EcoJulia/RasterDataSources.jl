module SSLTestWorldClim
using SimpleSDMLayers
using Test

download_raster(WorldClim, BioClim; layer=2, resolution=10.0)

end
