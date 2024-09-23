
layers(::Type{<:CHELSA{<:Future{BioClim}}}) = layers(BioClim)
layers(::Type{<:CHELSA{T}}) where T <:Future{BioClimPlus} = layers(T)
layerkeys(T::Type{<:CHELSA{<:Future{BioClim}}}, args...) = layerkeys(BioClim, args...)

layers(::Type{<:CHELSA{<:Future{Climate}}}) = (:prec, :temp, :tmin, :tmax)

date_step(::Type{<:CHELSA{<:Future{Climate,CMIP5}}}) = Year(20) 
date_step(::Type{<:CHELSA{<:Future{Climate,CMIP6}}}) = Year(30) 

# A modified key is used in the file name, while the key is used as-is in the path
const CHELSAKEY = (prec="pr", temp="tas", tmin="tasmin", tmax="tasmax", bio="bio")

"""
    getraster(T::Type{CHELSA{Future{BioClim}}}, [layer]; date) => String

Download CHELSA [`BioClim`](@ref) data, choosing layers from: `$(layers(CHELSA{BioClim}))`.

See the docs for [`Future`](@ref) for model choices.

Without a layer argument, all layers will be downloaded, and a `NamedTuple` of paths 
returned.

## Keywords

- `date`: a `Date` or `DateTime` object, a Vector, or Tuple of start/end dates.
    Note that CHELSA CMIP5 only has two datasets, for the periods 2041-2060 and
    2061-2080. CMIP6 has datasets for the periods 2011-2040, 2041-2070, and 2071-2100.
    Dates must fall within these ranges.

## Example
```julia
using RasterDataSources, Dates
getraster(CHELSA{Future{BioClim, CMIP6, GFDLESM4, SSP370}}, 1, date = Date(2050))
```

"""
function getraster(
    T::Type{<:CHELSA{<:Future{BioClim}}}, layers::Union{Tuple,Int,Symbol}; date
)
    _getraster(T, layers, date)
end

getraster_keywords(::Type{<:CHELSA{<:Future{BioClim}}}) = (:date,)

"""
    getraster(T::Type{CHELSA{Future{BioClimPlus}}}, [layer]; date) => String

Download CHELSA [`BioClimPlus`](@ref) data, choosing layers from: `$(layers(CHELSA{BioClimPlus}))`.

See the docs for [`Future`](@ref) for model choices.

Without a layer argument, all layers will be downloaded, and a `NamedTuple` of paths 
returned.

## Keywords

- `date`: a `Date` or `DateTime` object, a Vector, or Tuple of start/end dates.
    Note that CHELSA CMIP5 only has two datasets, for the periods 2041-2060 and
    2061-2080. CMIP6 has datasets for the periods 2011-2040, 2041-2070, and 2071-2100.
    Dates must fall within these ranges.

## Example
"""
function getraster(
    T::Type{<:CHELSA{<:Future{BioClimPlus}}}, layers::Union{Tuple,Int,Symbol}; date
)
    _getraster(T, layers, date)
end

getraster_keywords(::Type{<:CHELSA{<:Future{BioClimPlus}}}) = (:date,)


"""
    getraster(T::Type{CHELSA{Future{Climate}}}, [layer]; date, month) => String

Download CHELSA [`Climate`](@ref) data, choosing layers from: `$(layers(CHELSA{BioClim}))`.

See the docs for [`Future`](@ref) for model choices.

Without a layer argument, all layers will be downloaded, and a `NamedTuple` of paths returned.

## Keywords

- `date`: a `Date` or `DateTime` object, a Vector, or Tuple of start/end dates.
    Note that CHELSA CMIP5 only has two datasets, for the periods 2041-2060 and
    2061-2080. CMIP6 has datasets for the periods 2011-2040, 2041-2070, and 2071-2100.
    Dates must fall within these ranges.
- `month`: the month of the year, from 1 to 12, or a array or range of months like `1:12`.

## Example
```
using Dates, RasterDataSources
getraster(CHELSA{Future{Climate, CMIP6, GFDLESM4, SSP370}}, :prec; date = Date(2050), month = 1)
```
"""
function getraster(
    T::Type{<:CHELSA{<:Future{Climate}}}, layers::Union{Tuple,Symbol}; date, month
)
    _getraster(T, layers, date, month)
end

getraster_keywords(::Type{<:CHELSA{<:Future{Climate}}}) = (:date, :month)

function _getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layers, date, months::AbstractArray)
    map(month -> _getraster(T, layers, date, month), months)
end
function _getraster(
    T::Type{<:CHELSA{<:Future{Climate}}}, layers, dates::AbstractArray, months::AbstractArray
)
    map(date -> _getraster(T, layers, date, months), dates)
end
function _getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layers, dates::AbstractArray, month)
    map(date -> _getraster(T, layers; date, month), dates)
end
function _getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layers, dates::Tuple, months::AbstractArray)
    _getraster(T, layers, date_sequence(T, dates), months)
end
function _getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layers, dates::Tuple, month)
    _getraster(T, layers, date_sequence(T, dates), month)
end
function _getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layers, date, month)
    _getraster(T, layers; date, month)
end
function _getraster(T::Type{<:CHELSA{<:Future{BioClim}}}, layers, dates::AbstractArray)
    map(date -> _getraster(T, layers, date), dates)
end
function _getraster(T::Type{<:CHELSA{<:Future{BioClim}}}, layers, date::TimeType)
    _getraster(T, layers; date)
end
function _getraster(T::Type{<:CHELSA{<:Future{BioClimPlus}}}, layers, dates::AbstractArray)
    map(date -> _getraster(T, layers, date), dates)
end
function _getraster(T::Type{<:CHELSA{<:Future{BioClimPlus}}}, layers, date::TimeType)
    _getraster(T, layers; date)
end

# We have the extra args as keywords again to generalise rasterpath/rasterurl
function _getraster(T::Type{<:CHELSA{<:Future}}, layers::Tuple; kw...)
    _map_layers(T, layers; kw...)
end
_getraster(T::Type{<:CHELSA{<:Future{BioClim}}}, layer::Symbol; kw...) = _getraster(T, bioclim_int(layer); kw...)
function _getraster(T::Type{<:CHELSA{<:Future}}, layer::Union{Symbol,Integer}; kw...)
    _check_layer(T, layer)
    path = rasterpath(T, layer; kw...)
    url = rasterurl(T, layer; kw...)
    return _maybe_download(url, path)
end

function rastername(T::Type{<:CHELSA{<:Future}}, layer; kw...)
    _rastername(_phase(T), T, layer; kw...)
end

function _rastername(
    ::Type{CMIP5}, T::Type{<:CHELSA{<:Future{BioClim}}}, layer::Integer; date
)
    date_string = _date_string(_phase(T), date)
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    return "CHELSA_bio_mon_$(mod)_$(scen)_r1i1p1_g025.nc_$(layer)_$(date_string)_V1.2.tif"
end
function _rastername(
    ::Type{CMIP5}, T::Type{<:CHELSA{<:Future{Climate}}}, layer::Symbol; date, month
)
    date_string = _date_string(_phase(T), date)
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    key = CHELSAKEY[layer]
    suffix = layer === :prec ? "" : "_V1.2" # prec filenames dont end in _V1.2
    return "CHELSA_$(key)_mon_$(mod)_$(scen)_r1i1p1_g025.nc_$(month)_$(date_string)$(suffix).tif"
end
function _rastername(::Type{CMIP6}, T::Type{<:CHELSA{<:Future{BioClim}}}, layer::Integer; date)
    date_string = _date_string(_phase(T), date)
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    return "CHELSA_bio$(layer)_$(date_string)_$(mod)_$(scen)_V.2.1.tif"
end
function _rastername(::Type{CMIP6}, T::Type{<:CHELSA{<:Future{BioClimPlus}}}, layer::Symbol; date)
    date_string = _date_string(_phase(T), date)
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    return "CHELSA_$(layer)_$(date_string)_$(mod)_$(scen)_V.2.1.tif"
end
function _rastername(
    ::Type{CMIP6}, T::Type{<:CHELSA{<:Future{Climate}}}, layer::Symbol; date, month
)
    # CMIP6 Climate uses an underscore in the date string, of course
    date_string = replace(_date_string(_phase(T), date), "-" => "_")
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    key = CHELSAKEY[layer]
    mon = lpad(month, 2, '0')
    return "CHELSA_$(mod)_r1i1p1f1_w5e5_$(scen)_$(key)_$(mon)_$(date_string)_norm.tif"
end

function rasterpath(T::Type{<:CHELSA{<:Future}})
    joinpath(rasterpath(CHELSA), "Future", string(_dataset(T)), string(_scenario(T)), string(_model(T)))
end
function rasterpath(T::Type{<:CHELSA{<:Future}}, layer; kw...)
    joinpath(rasterpath(T), rastername(T, layer; kw...))
end

function rasterurl(T::Type{<:CHELSA{<:Future}}, layer; date, kw...)
    date_str = _date_string(_phase(T), date)
    key = _chelsa_layer(_dataset(T), layer)
    path = _urlpath(_phase(T), T::Type{<:CHELSA{<:Future}}, key, date_str)
    joinpath(rasterurl(CHELSA), path, rastername(T, layer; date, kw...))
end

_chelsa_layer(::Type{<:BioClim}, layer) = :bio
_chelsa_layer(::Type{<:BioClimPlus}, layer) = :bio
_chelsa_layer(::Type{<:Climate}, layer) = layer

function _urlpath(::Type{CMIP5}, T::Type{<:CHELSA{<:Future}}, name, date_str)
    return "chelsa_V1/cmip5/$date_str/$name/"
end
function _urlpath(::Type{CMIP6}, T::Type{<:CHELSA{<:Future}}, name, date_str)
    # The model is in uppercase in the URL for CMIP6
    mod = uppercase(_format(CHELSA, _model(T)))
    scen = _format(CHELSA, _scenario(T))
    key = CHELSAKEY[name]
    return "chelsa_V2/GLOBAL/climatologies/$date_str/$mod/$scen/$key/"
end

function _date_string(::Type{CMIP5}, date)
    if date < DateTime(2041)
        _cmip5_date_error(date)
    elseif date < DateTime(2061)
        "2041-2060"
    elseif date < DateTime(2081)
        "2061-2080"
    else
        _cmip5_date_error(date)
    end
end

function _date_string(::Type{CMIP6}, date)
    if date < DateTime(1981)
        _cmip6_date_error(date)
    elseif date < DateTime(2011)
        "1981-2010"
    elseif date < DateTime(2041)
        "2011-2040"
    elseif date < DateTime(2071)
        "2041-2070"
    elseif date < DateTime(2101)
        "2071-2100"
    else
        _cmip6_date_error(date)
    end
end

_cmip5_date_error(date) = error("CMIP5 covers the period from 2041-2080, not including $date")
_cmip6_date_error(date) = error("CMIP6 covers the period from 1981-2100, not including $date")

_dataset(::Type{<:CHELSA{F}}) where F<:Future = _dataset(F)
_phase(::Type{<:CHELSA{F}}) where F<:Future = _phase(F)
_model(::Type{<:CHELSA{F}}) where F<:Future = _model(F)
_scenario(::Type{<:CHELSA{F}}) where F<:Future = _scenario(F)

# Climate model string formatters for CHELSA Future

# CMIP5
const CHELSA_CMIP5_MODELS = Type{<:ClimateModel{CMIP5}}[]
const CHELSA_CMIP5_MODEL_STRINGS =
[
    "ACCESS1-0"
    "BNU-ESM"
    "CCSM4"
    "CESM1-BGC"
    "CESM1-CAM5"
    "CMCC-CMS"
    "CMCC-CM"
    "CNRM-CM5"
    "CSIRO-Mk3"
    "CanESM2"
    "FGOALS-g2"
    "FIO-ESM"
    "GFDL-CM3"
    "GFDL-ESM2G"
    "GFDL-ESM2M"
    "GISS-E2-H-CC"
    "GISS-E2-H"
    "GISS-E2-R-CC"
    "GISS-E2-R"
    "HadGEM2-AO"
    "HadGEM2-CC"
    "IPSL-CM5A-LR"
    "IPSL-CM5A-MR"
    "MIROC-ESM-CHEM"
    "MIROC-ESM"
    "MIROC5"
    "MPI-ESM-LR"
    "MPI-ESM-MR"
    "MRI-CGCM3"
    "MRI-ESM1"
    "NorESM1-M"
    "bcc-csm-1"
    "inmcm4"
]

# CMIP6
const CHELSA_CMIP6_MODELS = Type{<:ClimateModel{CMIP6}}[]
const CHELSA_CMIP6_MODEL_STRINGS = [
    "GFDL-ESM4"
    "IPSL-CM6A-LR"
    "MPI-ESM1-2-HR"
    "MRI-ESM2-0"
    "UKESM1-0-LL"
]

for CMIP in [:CMIP5, :CMIP6]
    strings = eval(Symbol("CHELSA_$(CMIP)_MODEL_STRINGS"))
    models = eval(Symbol("CHELSA_$(CMIP)_MODELS"))
    for model_str in strings
        type = Symbol(replace(model_str, "-" => "_"))
        @eval begin
            if !(@isdefined $type) 
                struct $type <: ClimateModel{$CMIP} end
                export $type
            end
            _format(::Type{CHELSA}, ::Type{$type}) = lowercase($model_str)
            push!($models, $type)
        end
    end
    append!(eval(Symbol("$(CMIP)_MODELS")), models)
    unique!(eval(Symbol("$(CMIP)_MODELS")))
end