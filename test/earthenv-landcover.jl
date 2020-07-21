module SSLTestEarthEnvLandCover
using SimpleSDMDataSources
using Test

download_raster(EarthEnv, LandCover; layer=2)

end
