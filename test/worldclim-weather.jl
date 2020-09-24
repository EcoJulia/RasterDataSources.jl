module SSLTestWorldClimWeather
using SimpleSDMDataSources, Test, Dates

using SimpleSDMDataSources: rastername, zipurl, zipname, zippath

raster_file = joinpath(ENV["ECODATASOURCES_PATH"], "WorldClim/Weather/prec/wc2.1_2.5m_prec_2001-01.tif")
@test rasterpath(WorldClim{Weather}, :prec, Date(2001, 1)) == raster_file
@test rastername(WorldClim{Weather}, :prec, Date(2001, 1)) == "wc2.1_2.5m_prec_2001-01.tif"


zip_file = joinpath(ENV["ECODATASOURCES_PATH"], "WorldClim/Weather/zips/wc2.1_2.5m_prec_2010-2018.zip")
@test zippath(WorldClim{Weather}, :prec, Date(2010)) == zip_file
@test zipurl(WorldClim{Weather}, :prec, Date(2010)) == 
    "https://biogeo.ucdavis.edu/data/worldclim/v2.1/hist/wc2.1_2.5m_prec_2010-2018.zip"
@test zipname(WorldClim{Weather}, :prec, Date(2010)) == 
    "wc2.1_2.5m_prec_2010-2018.zip"

# These files are 3GB each. Probably too big to test in CI.
# Not sure what to do about that.
# download_raster(WorldClim{Weather}, :prec, Date(2001):Month(1):Date(2001, 12))

end
