const WORLDCLIM_URI_CMIP6 = URI(scheme="https", host="geodata.ucdavis.edu", path="/cmip6")

layers(::Type{<:WorldClim{<:Future{Climate}}}) = (:tmin, :tmax, :prec)
getraster_keywords(::Type{<:WorldClim{<:Future{Climate}}}) = (:date, :res)


function getraster(T::Type{<:WorldClim{<:Future{Climate, CMIP6}}}, layers::Union{Tuple,Symbol}; 
    res::String=defres(T), date
)
    _getraster(T, layers, res, date)
end

function _getraster(T::Type{<:WorldClim{<:Future{Climate}}}, layer::Symbol, res::String, date)
    #date_str = _date_string(T, date)
    _check_layer(T, layer)
    _check_res(T, res)
    raster_path = rasterpath(T, "bioclim"; res, date)
    if !isfile(raster_path)
        _maybe_download(rasterurl(T, layer; res, date), raster_path)
    end
    return raster_path
end

function rasterurl(T::Type{<:WorldClim{<:Future}}, layer; res, date)
    joinpath(WORLDCLIM_URI_CMIP6, res, _format(T, _model(T)), _format(T, _scenario(T)), rastername(T, layer; res, date))
end

function rastername(T::Type{<:WorldClim{<:Future}}, layer; res, date)
    join(["wc2.1", res, string(layer), _format(T, _model(T)), _format(T, _scenario(T)), date], "_") * ".tif"
end

function getraster(T::Type{<:WorldClim{<:Future{BioClim, CMIP6}}}, layer::Symbol; res::String=defres(T), date)
    _getraster(T, layers, res, date)
end

function _getraster(T::Type{<:WorldClim{<:Future{BioClim}}}, layer::Symbol, res::String, date)
    #date_str = _date_string(T, date)
    #_check_layer(T, layer)
    #_check_res(T, res)
    raster_path = rasterpath(T; res, date)
    if !isfile(raster_path)
        _maybe_download(rasterurl(T, layer; res, date), raster_path)
    end
    return raster_path
end

# copy-pasted in from CHELSA - must be some way to implement this abstractly?
_dataset(::Type{<:WorldClim{F}}) where F<:Future = _dataset(F)
_phase(::Type{<:WorldClim{F}}) where F<:Future = _phase(F)
_model(::Type{<:WorldClim{F}}) where F<:Future = _model(F)
_scenario(::Type{<:WorldClim{F}}) where F<:Future = _scenario(F)



function _date_string(::Type{<:WorldClim{<:Future{Climate, CMIP6}}}, date)
    if date < DateTime(2021)
        _cmip6_date_error(date)
    elseif date < DateTime(2041)
        "2011-2040"
    elseif date < DateTime(2061)
        "2041-2060"
    elseif date < DateTime(2081)
        "2041-2080"
    elseif date < DateTime(2101)
        "2081-2100"
    else
        _cmip6_date_error(date)
    end
end

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
        export $type
        if !(@isdefined $type) 
            struct $type <: ClimateModel{CMIP6} end
            export $type
        end
        push!(WORDCLIM_CMIP6_MODELS, $type)
        _format(::Type{WorldClim}, ::Type{$type}) = $model_str
    end
end

append!(CMIP6_MODELS, WORDCLIM_CMIP6_MODELS)
unique!(CMIP6_MODELS)