module SSLTestWorldClimBioClim
using SimpleSDMDataSources
using Test

using SimpleSDMDataSources: rastername, zipurl, zipname, zippath

zip_file = "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_10m_bio.zip"
@test zipurl(WorldClim{BioClim}, 2, 10.0) == zip_file
@test zipname(WorldClim{BioClim}, 2, 10.0) == "wc2.1_10m_bio.zip"

raster_file = joinpath(ENV["ECODATASOURCES_PATH"], "WorldClim/BioClim/wc2.1_10m_bio_2.tif")
@test rasterpath(WorldClim{BioClim}, 2, 10.0) == raster_file
@test download_raster(WorldClim{BioClim}; layer=2, resolution=10.0) == raster_file
@test isfile(raster_file)

end
