## Shared
getraster_keywords(::Type{<:WorldClim{<:Future}}) = (:date, :res)

date_step(::Type{<:WorldClim{<:Future{<:Any,CMIP6}}}) = Year(20) 
date_range(::Type{<:WorldClim{<:Future{<:Any,CMIP6}}}) = (Date(2021), Date(2100))

function getraster(T::Type{<:WorldClim{<:Future}}, layers::Union{Tuple,Symbol,Int}; 
    res::String=defres(T), date
)
    _getraster(T, layers, res, date)
end

function _getraster(T::Type{<:WorldClim{<:Future}}, layers, res::String, dates)
    map(date -> _getraster(T, layers, res, date), date_sequence(T, dates))
end


## Climate
layers(::Type{<:WorldClim{<:Future{Climate}}}) = (:tmin, :tmax, :prec)

function _getraster(T::Type{<:WorldClim{<:Future{Climate}}}, layers::Tuple, res::String, date::TimeType)
    _map_layers(T, layers, res, date)
end
function _getraster(T::Type{<:WorldClim{<:Future{Climate}}}, layer::Symbol, res::String, date::TimeType)
    _check_layer(T, layer)
    _check_res(T, res)
    raster_path = rasterpath(T, layer; res, date)
    if !isfile(raster_path)
        _maybe_download(rasterurl(T, layer; res, date), raster_path)
    end
    return raster_path
end


## Bioclim
layers(::Type{<:WorldClim{<:Future{BioClim}}}) = layers(WorldClim{BioClim})

function getraster(T::Type{<:WorldClim{<:Future{BioClim, CMIP6}}}; res::String=defres(T), date)
    getraster(T, :bio1; res, date)
end

function _getraster(T::Type{<:WorldClim{<:Future{BioClim, CMIP6}}}, layers, res::String, date::TimeType)
    if layers isa Tuple
        for l in layers
            _check_layer(T, bioclim_int(l))
        end
    else
    _check_layer(T, bioclim_int(layers))
    end
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
    joinpath(rasterurl(T), res, _format(T, _model(T)), _format(T, _scenario(T)), rastername(T, args...; res, date))
end
rasterurl(T::Type{<:WorldClim{<:Future}}) = URI(scheme="https", host="geodata.ucdavis.edu", path="/cmip6")

function rastername(T::Type{<:WorldClim{<:Future}}, layer; res, date)
    join(["wc2.1", res, string(layer), _format(T, _model(T)), _format(T, _scenario(T)), _format(T, date)], "_") * ".tif"
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