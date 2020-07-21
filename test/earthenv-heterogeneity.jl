module SSLTestEarthEnvHabitatHeterogeneity
using SimpleSDMDataSources
using Test

download_raster(EarthEnv, HabitatHeterogeneity; layer=:Variance)

end
