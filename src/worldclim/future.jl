const WORLDCLIM_URI_CMIP6 = URI(scheme="https", host="geodata.ucdavis.edu", path="/cmip6")
layers(::Type{<:WorldClim{<:Future{BioClim}}}) = layers(WorldClim{BioClim})
layers(::Type{<:WorldClim{<:Future{Climate}}}) = (:tmin, :tmax, :prec)
getraster_keywords(::Type{<:WorldClim{<:Future}}) = (:date, :res)

function getraster(T::Type{<:WorldClim{<:Future{Climate, CMIP6}}}, layers::Union{Tuple,Symbol}; 
    res::String=defres(T), date
)
    _getraster(T, layers, res, date)
end

function _getraster(T::Type{<:WorldClim{<:Future{Climate}}}, layer::Symbol, res::String, date)
    _check_layer(T, layer)
    _check_res(T, res)
    raster_path = rasterpath(T, layer; res, date)
    if !isfile(raster_path)
        _maybe_download(rasterurl(T, layer; res, date), raster_path)
    end
    return raster_path
end

## Bioclim
getraster_keywords(::Type{<:WorldClim{<:Future{BioClim}}}) = (:date, :res)
# Future worldclim bioclim variables are in one big file. This is for syntax consistency
function getraster(T::Type{<:WorldClim{<:Future{BioClim, CMIP6}}}, layers::Union{Tuple,Symbol,Int}; kw...)
    if layers isa Tuple
        for l in layers
            _check_layer(WorldClim{BioClim}, bioclim_int(l))
        end
    else
        _check_layer(WorldClim{BioClim}, bioclim_int(layers))
    end
    getraster(T; kw...)
end
function getraster(T::Type{<:WorldClim{<:Future{BioClim, CMIP6}}}; res::String=defres(T), date)
    _getraster(T, res, date)
end

function _getraster(T::Type{<:WorldClim{<:Future{BioClim}}}, res::String, date)
    _check_res(T, res)
    raster_path = rasterpath(T; res, date)
    if !isfile(raster_path)
        _maybe_download(rasterurl(T; res, date), raster_path)
    end
    return raster_path
end

function rasterpath(T::Type{<:WorldClim{<:Future}}, args...; res, date) # splat to make sure this works with and without layer argument
    joinpath(rasterpath(T), rastername(T, args...; res, date))
end
function rasterpath(T::Type{<:WorldClim{<:Future}})
    joinpath(rasterpath(WorldClim), "Future", _format(T, _dataset(T)), _format(T, _scenario(T)), _format(T, _model(T)))
end

function rasterurl(T::Type{<:WorldClim{<:Future}}, args...; res, date)
    joinpath(WORLDCLIM_URI_CMIP6, res, _format(T, _model(T)), _format(T, _scenario(T)), rastername(T, args...; res, date))
end

function rastername(T::Type{<:WorldClim{<:Future}}, layer; res, date)
    join(["wc2.1", res, string(layer), _format(T, _model(T)), _format(T, _scenario(T)), _date_string(T, date)], "_") * ".tif"
end
rastername(T::Type{<:WorldClim{<:Future{BioClim}}}; kw...) = rastername(T, "bioc"; kw...)
rastername(T::Type{<:WorldClim{<:Future{BioClim}}}, layers::Union{Tuple,Symbol,Int}; kw...) = rastername(T, "bioc"; kw...)

# copy-pasted in from CHELSA - must be some way to implement this abstractly?
_dataset(::Type{<:WorldClim{F}}) where F<:Future = _dataset(F)
_phase(::Type{<:WorldClim{F}}) where F<:Future = _phase(F)
_model(::Type{<:WorldClim{F}}) where F<:Future = _model(F)
_scenario(::Type{<:WorldClim{F}}) where F<:Future = _scenario(F)

# overload _format
_format(::Type{<:WorldClim}, T::Type{<:SharedSocioeconomicPathway}) = lowercase(_format(T))


function _date_string(::Type{<:WorldClim{<:Future{<:Any, CMIP6}}}, date)
    if date < DateTime(2021)
        _cmip6_date_error(date)
    elseif date < DateTime(2041)
        "2021-2040"
    elseif date < DateTime(2061)
        "2041-2060"
    elseif date < DateTime(2081)
        "2041-2060"
    elseif date < DateTime(2101)
        "2081-2100"
    else
        _cmip6_date_error(date)
    end
end


## Handle all the models
const WORDCLIM_CMIP6_MODEL_STRINGS = [
    "ACCESS-CM2"
    "BCC-CSM2-MR"
    "CMCC-ESM2"
    "EC-Earth3-Veg"
    "FIO-ESM-2-0"
    "GFDL-ESM4"
    "GISS-E2-1-G"
    "HadGEM3-GC31-LL"
    "INM-CM5-0"
    "IPSL-CM6A-LR"
    "MIROC6"
    "MPI-ESM1-2-HR"
    "MRI-ESM2-0"
    "UKESM1-0-LL"
]

WORDCLIM_CMIP6_MODELS = Type{<:ClimateModel{CMIP6}}[]

for model_str in WORDCLIM_CMIP6_MODEL_STRINGS
    type = Symbol(replace(model_str, "-" => "_"))
    @eval begin
        if !(@isdefined $type) 
            struct $type <: ClimateModel{CMIP6} end
        end
        push!(WORDCLIM_CMIP6_MODELS, $type)
    end
end

append!(CMIP6_MODELS, WORDCLIM_CMIP6_MODELS)
unique!(CMIP6_MODELS)