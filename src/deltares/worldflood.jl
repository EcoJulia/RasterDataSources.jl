struct Deltares{Description} <: RasterDataSource end

struct WorldFlood end

function _validate_deltares_worldflood_params(; year, res, dem_source, return_period)
  # check the parameters
  # resolution depends on dem_source
  if dem_source == :NASADEM || dem_source == :MERITDEM
    @assert res in ("90m", "1km") "Provided: $res, expected one of "
  elseif dem_source == :LIDAR
    @assert res == "5km" "Provided: $res, expected one of "
  else
    @assert dem_source in (:NASADEM, :MERITDEM, :LIDAR) "Provided: $dem_source, expected one of "
  end
  
  @assert return_period in (0, 2, 5, 10, 25, 50, 100, 250) "Provided: $return_period, expected one of "
  @assert year in (2018, 2050) "Provided: $year, expected one of "
  return true
end


getraster_keywords(::Type{<: Deltares{<: WorldFlood}}) = (:year, :res, :dem_source, :return_period)

function rastername(::Type{<: Deltares{<: WorldFlood}}, layer; year = 2050, res::String = "90m", dem_source::Symbol = :NASADEM, return_period::Int = 100)
  
  # validate params
  _validate_deltares_worldflood_params(; year, res, dem_source, return_period)
  "GFM_global_$(dem_source)$(res)_$(year)slr_rp$(lpad(return_period, 4, '0'))_masked.nc"
  
end

function rasterpath(T::Type{<: Deltares{<: WorldFlood}}, layer; year = 2050, res::String = "90m", dem_source::Symbol = :NASADEM, return_period::Int = 100)
 
  # validate params
  _validate_deltares_worldflood_params(; year, res, dem_source, return_period)
  return joinpath(rasterpath(), "Deltares", "WorldFlood", rastername(T, layer; year, res, dem_source, return_period))
    
end

function rasterurl(T::Type{<: Deltares{<: WorldFlood}}, layer; year = 2050, res::String = 90, dem_source::Symbol = :NASADEM, return_period::Int = 100)
  
  # validate params
  _validate_deltares_worldflood_params(; year, res, dem_source, return_period)
  
  root_uri = URI(scheme = "https", host = "deltaresfloodssa.blob.core.windows.net", path = "/floods/v2021.06")
  
  return URIs.URI(root_uri, path = "/floods/v2021.06/global/$(dem_source)/$(res)/" * rastername(T, layer; year, res, dem_source, return_period))
  
end

function getraster(T::Type{<: Deltares{<: WorldFlood}}, layer; year = 2050, res::String = "90m", dem_source::Symbol = :NASADEM, return_period::Int = 100)
  raster_path = rasterpath(T, layer; year, res, dem_source, return_period)
  mkpath(dirname(raster_path))
  _maybe_download(rasterurl(T, layer; year, res, dem_source, return_period), raster_path)
  raster_path
end
