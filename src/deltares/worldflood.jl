struct Deltares{Description} <: RasterDataSource end

struct WorldFlood end

function _validate_deltares_worldflood_params(; sea_level_year, resolution, dem_source, return_period)
  # check the parameters
  # resolution depends on dem_source
  if dem_source == :NASADEM || dem_source == :MERITDEM
    @assert resolution in (90, 1000)
  elseif dem_source == :LIDAR
    @assert resolution == 5000
  else
    @assert dem_source in (:NASADEM, :MERITDEM, :LIDAR)
  end
  
  @assert return_period in (0, 2, 5, 10, 25, 50, 100, 250)
  @assert sea_level_year in (2018, 2050)
  return true
end

getraster_keywords(::Type{<: Deltares{<: WorldFlood}}) = (:resolution, :dem_source, :return_period)

function rastername(::Type{<: Deltares{<: WorldFlood}}, sea_level_year = 2050; resolution::Int = 90, dem_source::Symbol = :NASADEM, return_period::Int = 100)
  
  # validate params
  _validate_deltares_worldflood_params(; sea_level_year, resolution, dem_source, return_period)
  "GFM_global_$(dem_source)$(resolution)m_$(sea_level_year)_slr_rp$(return_period)_masked.nc"
  
end

function rasterpath(T::Type{<: Deltares{<: WorldFlood}}, sea_level_year = 2050; resolution::Int = 90, dem_source::Symbol = :NASADEM, return_period::Int = 100)
 
  # validate params
  _validate_deltares_worldflood_params(; sea_level_year, resolution, dem_source, return_period)
  return joinpath(rasterpath(), "Deltares", "WorldFlood", rastername(T, sea_level_year; resolution, dem_source, return_period))
    
end

function rasterurl(T::Type{<: Deltares{<: WorldFlood}}, sea_level_year = 2050; resolution::Int = 90, dem_source::Symbol = :NASADEM, return_period::Int = 100)
  
  # validate params
  _validate_deltares_worldflood_params(; sea_level_year, resolution, dem_source, return_period)
  
  root_uri = URI(scheme = "https", host = "deltaresfloodssa.blob.core.windows.net", path = "/floods/v2021.06")
  
  return URIs.URI(root_uri, path = "/global/$(dem_source)/$(resolution)m/" * rastername(T, sea_level_year; resolution, dem_source, return_period))
  
end

function getraster(T::Type{<: Deltares{<: WorldFlood}}, sea_level_year = 2050; resolution::Int = 90, dem_source::Symbol = :NASADEM, return_period::Int = 100)
  raster_path = rasterpath(T, sea_level_year; resolution, dem_source, return_period)
  mkpath(dirname(raster_path))
  _maybe_download(rasterurl(T, sea_level_year; resolution, dem_source, return_period), raster_path)
  raster_path
end
