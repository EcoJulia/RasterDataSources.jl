module SSLTestCHELSABioClim
using SimpleSDMDataSources
using Test

download_raster(CHELSA, BioClim; layer=5)

end
