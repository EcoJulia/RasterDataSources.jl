# Types

#= ALWB has a lot of data sources - with varying
degrees of nesting. Here wee use types to navigate
and structure the nesting, instead of just using 
symbols. 

Symbols may be better, idk. They don't need to be imported which is good, 
but there is more room for mistakes/confusion around grounpings
and categories with symbols - which this dataset has a lot of.
=#

const ALWB_URI = URI(scheme="http", host="www.bom.gov.au", path="/jsp/awra/thredds/fileServer/AWRACMS")

abstract type DataMode end

"""
Get as the regular measured values.
"""
struct Values <: DataMode end
"""
Get the dataset in relative deciles.
"""
struct Deciles <: DataMode end

const ALWBperiod = Union{Day,Month,Year}

struct ALWB{M<:DataMode,D<:ALWBperiod} <: RasterDataSource end

# Precipitation
struct Precipiation end

# SoilMoisture
struct SoilMoisture{X} end
struct Upper end
struct Lower end
struct Deep end
struct RootZone end 

# Runoff
"""
    Runoff

Runoff in mm. Only one dataset. 
Available in `Values` and `Deciles` for `Day`, `Month`, and `Year`.
"""
struct Runoff end

# Evapotranspiration

"""
    Evapotrans{X}

[`Actual`](@ref), [`Potential`](@ref), [`Refcrop`](@ref) datasets.
"""
struct Evapotrans{X} end

struct Actual end

struct Potential{X} end
struct Landscape end
struct Areal end
struct SyntheticPan end

struct RefCrop{X} end
struct Short end
struct Tall end 

# Evaporation
struct Evaporation{X} end
struct OpenWater end

# Deep Drainage
struct DeepDrainage end



# Interface methods

layers(::Type{<:ALWB}) = 
    (SoilMoisture{Upper}, SoilMoisture{Lower}, SoilMoisture{Deep}, SoilMoisture{RootZone},
     Evapotrans{Actual}, Evapotrans{Potential{Landscape}}, Evapotrans{Potential{Areal}}, 
     Evapotrans{Potential{SyntheticPan}}, Evapotrans{RefCrop{Short}}, Evapotrans{RefCrop{Tall}}, 
     Precipiation, Runoff, Evaporation{OpenWater}, DeepDrainage)

rastername(T::Type{<:ALWB{M,P}}, layer, date) where {M,P} =
    _pathsegment(layer) * _pathsegment(P, date) * ".nc"

rasterpath(::Type{ALWB}) = joinpath(rasterpath(), "ALWB")
rasterpath(::Type{ALWB{M,P}}) where {M,P} =
    joinpath(joinpath(rasterpath(), "ALWB"), map(_pathsegment, (M, P))...)
rasterpath(T::Type{<:ALWB}, layer) = joinpath(rasterpath(T), _pathsegment(layer))
rasterpath(T::Type{<:ALWB}, layer, date) =
    joinpath(rasterpath(T), rastername(T, layer, date))

rasterurl(T::Type{<:ALWB{M,P}}, layer, date) where {M,P} =
    joinpath(ALWB_URI, _pathsegment(T), rastername(T, layer, date))

download_raster(T::Type{<:ALWB}, layers::Tuple=layers(T); kwargs...) =
    map(l -> download_raster(T, l; kwargs...), layers)
function download_raster(T::Type{<:ALWB{M,P}}, layer::Type; dates) where {M,P} 
    _check_layer(T, layer)
    dates = _date_sequence(dates, P(1))
    mkpath(rasterpath(T, layer))
    raster_paths = String[]
    for d in dates
        url = rasterurl(T, layer, d)
        path = rasterpath(T, layer, d)
        _maybe_download(url, path)
        push!(raster_paths, path)
    end
    raster_paths
end



# Utilitiy methods

_date_sequence(dates::AbstractArray, step) = dates
_date_sequence(dates::Tuple, step) = first(dates):step:last(dates)

_date2string(t, date) = Dates.format(date, _dateformat(t))
_string2date(t, d::AbstractString) = Date(d, _dateformat(t))


# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/rain_day_2017.nc
_pathsegment(::Type{Precipiation}) = "rain_day"

_pathsegment(::Type{SoilMoisture{Upper}}) = "s0_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/ss_pct_2017.nc
_pathsegment(::Type{SoilMoisture{Lower}}) = "ss_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/sd_pct_2017.nc
_pathsegment(::SoilMoisture{Deep}) = "sd_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/sm_pct_2017.nc
_pathsegment(::Type{SoilMoisture{RootZone}}) = "sm_pct"

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/qtot_2017.nc
_pathsegment(::Type{Runoff}) = "qtot"

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/etot_2017.nc
_pathsegment(::Type{Evapotrans{Actual}}) = "etot"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/e0_2017.nc
_pathsegment(::Type{Evapotrans{Potential{Landscape}}}) = "e0"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/ma_wet_2017.nc
_pathsegment(::Type{Evapotrans{Potential{Areal}}}) = "ma_wet"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/pen_pet_2017.nc
_pathsegment(::Type{Evapotrans{Potential{SyntheticPan}}}) = "pen_pet"

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/fao_pet_2017.nc
_pathsegment(::Type{Evapotrans{RefCrop{Short}}}) = "fao_pet"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/asce_pet_2017.nc 
_pathsegment(::Type{Evapotrans{RefCrop{Tall}}}) = "asce_pet"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/etot_2017.nc

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/msl_wet_2017.nc
_pathsegment(::Type{Evaporation{OpenWater}}) = "msl_wet"

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/dd_2017.nc
_pathsegment(::Type{DeepDrainage}) = "dd"

_pathsegment(::Type{ALWB{M,P}}) where {M,P} = joinpath(_pathsegment(M), _pathsegment(P))
_pathsegment(::Type{Values}) = "values"
_pathsegment(::Type{Deciles}) = "deciles"
_pathsegment(::Type{Day}) = "day"
_pathsegment(::Type{Month}) = "month"
_pathsegment(::Type{Year}) = "year"
# Days are in whole-year files
_pathsegment(::Type{Day}, date) = "_" * string(year(date))
# Months and years are all in one file
_pathsegment(::Type{<:Union{Year,Month}}, date) = ""
