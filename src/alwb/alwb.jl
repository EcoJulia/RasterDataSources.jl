
const ALWB_URI = URI(scheme="http", host="www.bom.gov.au", path="/jsp/awra/thredds/fileServer/AWRACMS")

abstract type DataMode end

"""
    Values <: DataMode

Get the dataset as regular measured values.
"""
struct Values <: DataMode end

"""
    Deciles <: DataMode

Get the dataset in relative deciles.
"""
struct Deciles <: DataMode end

struct ALWB{M<:DataMode,D<:Union{Day,Month,Year}} <: RasterDataSource end

layers(::Type{<:ALWB}) = (
    :rain_day, :s0_pct, :ss_pct, :sd_pct, :sm_pct, :qtot, :etot, 
    :e0, :ma_wet, :pen_pet, :fao_pet, :asce_pet, :msl_wet, :dd
)

@doc """
    ALWB{Union{Deciles,Values},Union{Day,Month,Year}} <: RasterDataSource

Data from the Australian Landscape Water Balance (ALWB) data source.

See: [www.bom.gov.au/water/landscape](http://www.bom.gov.au/water/landscape)

The available layers are: `$(layers(ALWB))`, available in daily, monthly and 
annual resolutions, and as `Values` or relative `Deciles`.

`getraster` for `ALWB` must use a `date` keyword to specify the date to download.
""" ALWB

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/rain_day_2017.nc
# Precipiation = "rain_day"

# SoilMoisture_Upper = "s0_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/ss_pct_2017.nc
# SoilMoisture_Lower = "ss_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/sd_pct_2017.nc
# SoilMoisture_Deep = "sd_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/sm_pct_2017.nc
# SoilMoisture_RootZone = "sm_pct" # http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/qtot_2017.nc # Runoff = "qtot"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/etot_2017.nc
# Evapotrans_Actual = "etot"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/e0_2017.nc
# Evapotrans_Potential_Landscape = "e0"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/ma_wet_2017.nc
# Evapotrans_Potential_Areal = "ma_wet"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/pen_pet_2017.nc
# Evapotrans_Potential_SyntheticPan = "pen_pet"

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/fao_pet_2017.nc
# Evapotrans_RefCrop_Short = "fao_pet"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/asce_pet_2017.nc 
# Evapotrans_RefCrop_Tall = "asce_pet"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/etot_2017.nc

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/msl_wet_2017.nc
# Evaporation_OpenWater = "msl_wet"

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/dd_2017.nc
# DeepDrainage = "dd"


"""
    getraster(source::Type{<:ALWB{Union{Deciles,Values},Union{Day,Month,Year}}}, [layer]; date)

Download [`ALWB`](@ref) weather data from 
[www.bom.gov.au/water/landscape](http://www.bom.gov.au/water/landscape) as values or 
deciles with timesteps of `Day`, `Month` or `Year`.

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(layers(ALWB))`. Without a 
    `layer` argument, all layers will be downloaded, and a `Vector` of paths returned.

# Keywords
- `date`: a `DateTime`, `AbstractVector` of `DateTime` or a `Tuple` of start and end dates.
    For multiple dates, multiple filenames will be returned. AWAP is available with a daily
    timestep.

# Example
This will return the file containing annual averages, including your date:

```julia
julia> getraster(ALWB{Values,Year}, :ss_pct; date=Date(2001, 2))
"/your/RASTERDATASOURCES_PATH/ALWB/values/month/ss_pct.nc"
```

Returns the filepath/s of the downloaded or pre-existing files.
"""
function getraster(T::Type{<:ALWB}, layers::Union{Tuple,Symbol}; date)
     _getraster(T, layers, date)
end

function _getraster(T::Type{<:ALWB{M,P}}, layers, dates::Tuple) where {M,P}
    _getraster(T, layers, _date_sequence(dates, P(1)))
end
function _getraster(T::Type{<:ALWB}, layers, dates::AbstractArray)
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{<:ALWB}, layers::Tuple, date::Dates.TimeType)
    _map_layers(T, layers, date)
end
function _getraster(T::Type{<:ALWB}, layer::Symbol, date::Dates.TimeType)
    _check_layer(T, layer)
    mkpath(rasterpath(T))
    url = rasterurl(T, layer; date=date)
    path = rasterpath(T, layer; date=date)
    _maybe_download(url, path)
    path
end

rastername(T::Type{<:ALWB{M,P}}, layer; date) where {M,P} =
    string(layer, _pathsegment(P, date), ".nc")

rasterpath(::Type{ALWB}) = joinpath(rasterpath(), "ALWB")
rasterpath(::Type{ALWB{M,P}}) where {M,P} =
    joinpath(joinpath(rasterpath(), "ALWB"), map(_pathsegment, (M, P))...)
rasterpath(T::Type{<:ALWB}, layer; date=nothing) =
    joinpath(rasterpath(T), rastername(T, layer; date))

rasterurl(T::Type{<:ALWB{M,P}}, layer; date) where {M,P} =
    joinpath(ALWB_URI, _pathsegments(T)..., rastername(T, layer; date))

# Utility methods

_pathsegments(::Type{ALWB{M,P}}) where {M,P} = _pathsegment(M), _pathsegment(P)
_pathsegment(::Type{Values}) = "values"
_pathsegment(::Type{Deciles}) = "deciles"
_pathsegment(::Type{Day}) = "day"
_pathsegment(::Type{Month}) = "month"
_pathsegment(::Type{Year}) = "year"
# Days are in whole-year files
_pathsegment(::Type{Day}, date) = "_" * string(year(date))
# Months and years are all in one file
_pathsegment(::Type{<:Union{Year,Month}}, date) = ""
