# Types

#= ALWB has a lot of data sources - with varying
degrees of nesting. Here wee use types to navigate
and structure the nesting, instead of just using 
symbols.
=#

const ALWB_URL = "http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS"

abstract type DataMode end

struct Values <: DataMode end
struct Deciles <: DataMode end

const ALWBperiod = Union{Day,Month,Year}

struct ALWB{M<:DataMode,D<:ALWBperiod} <: SDMDataSource end

struct ReferenceCrop end

struct SoilMoisture{X} end
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/s0_pct_2017.nc
struct Upper end
_pathsegment(::SoilMoisture{Upper}) = "s0_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/ss_pct_2017.nc
struct Lower end
_pathsegment(::SoilMoisture{Lower}) = "ss_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/sd_pct_2017.nc
struct Deep end
_pathsegment(::SoilMoisture{Deep}) = "sd_pct"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/sm_pct_2017.nc
struct RootZone end 
_pathsegment(::SoilMoisture{RootZone}) = "sm_pct"

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/rain_day_2017.nc
struct Precipiation end
_pathsegment(::Precipiation) = "rain_day"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/qtot_2017.nc
struct Runoff end
_pathsegment(::Runoff) = "qtot"

struct Evapotrans{X} end
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/etot_2017.nc
struct Actual end
_pathsegment(::Evapotrans{Actual}) = "etot"

struct Potential{X} end
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/e0_2017.nc
struct Landscape end
_pathsegment(::Evapotrans{Potential{Landscape}}) = "e0"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/ma_wet_2017.nc
struct Areal end
_pathsegment(::Evapotrans{Potential{Areal}}) = "ma_wet"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/pen_pet_2017.nc
struct SyntheticPan end
_pathsegment(::Evapotrans{Potential{SyntheticPan}}) = "pen_pet"

struct RefCrop{X} end
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/fao_pet_2017.nc
struct Short end
_pathsegment(::RefCrop{Short}) = "fao_pet"
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/asce_pet_2017.nc
struct Tall end
_pathsegment(::RefCrop{Tall}) = "asce_pet"

# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/etot_2017.nc

struct Evaporation{X} end
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/msl_wet_2017.nc
struct OpenWater end
_pathsegment(::Evaporation{OpenWater}) = "msl_wet"
#
# http://www.bom.gov.au/jsp/awra/thredds/fileServer/AWRACMS/values/day/dd_2017.nc
struct DeepDrainage end
_pathsegment(::DeepDrainage) = "dd"



# Interface methods

rasterpath(::Type{<:ALWB{M,P}}) where {M,P} =
    joinpath(rasterpath(), "ALWB", map(_pathsegment, (M, P))...)
rasterpath(T::Type{<:ALWB}, layer) = joinpath(rasterpath(T), _pathsegment(layer))
rasterpath(T::Type{<:ALWB}, layer, date) =
    joinpath(rasterpath(T, layer), rastername(T, layer, date))

rastername(T::Type{<:ALWB{M,P}}, layer, date) where {M,P}=
    joinpath(_pathsegment(layer), _pathsegment(P, date), ".nc")

rasterurl(T::Type{<:ALWB{M,P}}, layer, date) where {M,P} =
    joinpath(ALWB_URL, _pathsegment(layer), rastername(T, layer, date))

# Days and months are in whole-year files
_pathsegment(P::Type{<:Union{Day,Month}}, date) = string(year(date))
# The years are all in one file
_pathsegment(P::Type{Year}, date) = ""

# download_raster(::Type{<:ALWB}; dates, kwargs...) = download_raster(T, AWAP_ALL; dates, kwargs...)
function download_raster(T::Type{<:ALWB{M,P}}, layer::Type; dates) where {M,P}
    dates = _date_sequence(dates, P(1))
    mkpath(rasterpath(T, layer))
    raster_paths = String[]
    for d in dates
        s = _pathsegments(T)
        url = rasterurl(T, layer, d)
        raster_path = rasterpath(T, layer, d)
        _maybe_download(rasterurl(T, layer, d), raster_path)
        push!(raster_paths, raster_path)
    end
    raster_paths
end


# Utilitiy methods

_date_sequence(dates::AbstractArray, step) = dates
_date_sequence(dates::Tuple, step) = first(dates):step:last(dates)

_date2string(t, date) = Dates.format(date, _dateformat(t))
_string2date(t, d::AbstractString) = Date(d, _dateformat(t))


_pathsegment(::Values) = "values"
_pathsegments(::Deciles) = "deciles"
_pathsegment(::Day) = "day"
_pathsegment(::Month) = "month"
_pathsegment(::Year) = "year"
