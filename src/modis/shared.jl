"""
    MODIS{ModisProduct} <: RasterDataSource

MODIS/VIIRS Land Product Database. Vegetation indices, surface reflectance, and more land cover data. Data from [`ModisProduct`](@ref)s datasets. 

See: [modis.ornl.gov](https://modis.ornl.gov/)
"""
struct MODIS{X} <: RasterDataSource end

function layerkeys(T::Type{MODIS{X}}) where X 
    layernames = list_layers(X)

    keys = []
    # For some products, layers have names that start with numbers, thus 
    # resulting in bad Symbol names. Here we remove some words from each
    # layer name until it's in a good format.
    for l in layernames
        newname = []
        words = split(l, "_")
        beginning = true
        for w in words # keep only "clean" words
            if beginning
                if match(r"^[0-9]|^days|^m|^meters", w) === nothing
                    push!(newname, w)
                    beginning = false # added one word: no more checks
                end
            else
                push!(newname, w)
            end
        end
        push!(keys, Symbol(join(newname, "_"))) # build Array of newname Symbols
    end
    return Tuple(collect(keys)) # build tuple from Array{Symbol}
end

"""
    layerkeys(T::Type{<:ModisProduct}) => Tuple

`Tuple` of `Symbol`s corresponding to the available layers for a given product.
May issue a request to MODIS server to get the layers list, or might just read
this information if the correctly named file is available.
"""
layerkeys(T::Type{<:ModisProduct}) = layerkeys(MODIS{T})

function layerkeys(T::Type{<:MODIS{X}}, layers::Tuple) where X
    if isa(layers[1], Int) # integer layer names get their key name
        layerkeys(T)[collect(layers)]
    else # if all elements of layers are correct layer keys, return them
        all(k -> k in layerkeys(T), layers) && return(layers)
        throw("Unknown layers in $layers")
    end
end

layerkeys(T::Type{<:ModisProduct}, layers) = layerkeys(MODIS{T}, layers)

function layers(T::Type{MODIS{X}}) where X
    return Tuple(1:length(layerkeys(T)))
end

layers(T::Type{<:ModisProduct}) = layers(MODIS{T})

function getraster(T::Type{<:MODIS{X}}, args...; kwargs...) where X
    X <: ModisProduct ?
        getraster(X, args...; kwargs...) :
        throw("Unrecognized MODIS product.")
end 

"""
    getraster(T::Union{Type{<:ModisProduct}, Type{MODIS{X}}}, [layer::Union{Tuple,AbstractVector,Integer, Symbol}]; kwargs...) => Union{String, AbstractVector, NamedTuple}

Download [`MODIS`](@ref) data for a given [`ModisProduct`](@ref).

# Arguments

- `layer`: `Integer` or tuple/range of `Integer` or `Symbol`s. Without a `layer` argument, all layers will be downloaded, and a `NamedTuple` of paths returned.

Available layers for a given product can be looked up using [`RasterDataSources.layerkeys(T::Type{<:ModisProduct})`](@ref).

# Keywords

- `lat` and `lon`: Coordinates in decimal degrees of the approximate center of the raster. The MODIS API will try to match its pixel grid system as close as possible to those coordinates.

- `km_ab` and `km_lr``: Half-width and half-height of the raster in kilometers. Currently only `Integer` values are supported.

- `date`: `String`, `Date`, `DateTime`, `AbstractVector` or `Tuple` of dates for the request. If `date` is iterable and of length 2, it is considered to contain the start and the end date of the request. `String`s should be in format YYYY-MM-DD but can be in similar formats as long as they are comprehensible by `Dates.Date`. The available date interval for MODIS is 16 days.

Will download several files, one for each date, and returns the filepath/s of the downloaded or pre-existing files.
"""
function getraster(T::Type{<:ModisProduct}, layer::Union{Tuple, Symbol, Int}=layerkeys(T);
    lat::Real,
    lon::Real,
    km_ab::Int,
    km_lr::Int,
    date::Union{Tuple, AbstractVector, String, Date, DateTime}
)
    # first check all arguments
    check_layers(T, layer)
    check_kwargs(T; 
        lat = lat,
        lon = lon,
        km_ab = km_ab,
        km_lr = km_lr,
        date = date
    )

    # then pass them to internal functions
    _getraster(T, layer, date;
        lat = lat,
        lon = lon,
        km_ab = km_ab,
        km_lr = km_lr
    )
end

# if layer is a tuple, get them all using _map_layers
function _getraster(T::Type{<:ModisProduct}, layers::Tuple, date; kwargs...)
    _map_layers(T, layers, date; kwargs...)
end

# convert layer symbols to int
function _getraster(T::Type{<:ModisProduct}, layer::Symbol, date; kwargs...)
    _getraster(T, modis_int(T, layer), date; kwargs...)
end

# Tuple : start and end date
function _getraster(T::Type{<:ModisProduct}, layer::Int, date::Tuple;
    kwargs...)
    _getraster(
        T, layer, kwargs[:lat], kwargs[:lon],
        kwargs[:km_ab], kwargs[:km_lr], string(Date(date[1])),
        string(Date(date[2]))
    )
end

# Handle vectors : map over dates
function _getraster(T::Type{<:ModisProduct}, layer::Int,
    date::AbstractVector;
    kwargs...
)
    out = String[]
    for d in eachindex(date)
        push!(out, _getraster(T, layer, date[d]; kwargs...))
    end
    return out
end

# single date : from = to = string(Date(date))
function _getraster(T::Type{<:ModisProduct}, layer::Int,
    date::Union{Dates.TimeType, String};
    kwargs...
)
    _getraster(T, layer, kwargs[:lat], kwargs[:lon], kwargs[:km_ab], kwargs[:km_lr], string(Date(date)), string(Date(date)))
end


"""
    _getraster(T::Type{<:ModisProduct}, layer::Int, lat::Real, lon::Real, km_ab::Int, km_lr::Int, from::String, to::String) => Union{String, Vector{String}}

Modis requests always have an internal start and end date: using from and to in internal arguments makes more sense. `date` argument is converted by various
_getraster dispatches before calling this.
"""
function _getraster(T::Type{<:ModisProduct}, layer::Int,
    lat::Real,
    lon::Real,
    km_ab::Int,
    km_lr::Int,
    from::String,
    to::String
)
    # accessing dates in a format readable by the MODIS API
    dates = list_dates(T;
        lat = lat,
        lon = lon,
        format = "ModisDate",
        from = from,
        to = to
    )

    length(dates) == 0 && throw(
        "No available $T data at $lat , $lon from $from to $to"
    )

    if length(dates) <= 10
        files = _getrasterchunk(T, layer;
            lat = lat,
            lon = lon,
            km_ab = km_ab,
            km_lr = km_lr,
            dates = dates
        )
    else
        # take "chunk" subsets of dates 10 by 10
        n_chunks = div(length(dates), 10) +1
        chunks = [dates[1+10*k:(k == n_chunks -1 ? end : 10*k+10)] for k in 0:(n_chunks-1)]
        
        # remove empty end chunk
        # (happens when length(dates) is divisible by 10)
        length(chunks[end]) == 0 && (chunks = chunks[1:(end-1)]) 

        files = map(chunks) do c
            _getrasterchunk(T, layer;
                dates = c,
                lat = lat,
                lon = lon,
                km_ab = km_ab,
                km_lr = km_lr
            )
        end

        files = vcat(files...) # splat chunks to get only one list
    end

    return files
end

"""
    _getrasterchunk(T::Type{<:ModisProduct}, layer::Int; dates::Vector{String}, kwargs...)

Internal calls of [`RasterDataSources.modis_request`](@ref) and [`RasterDataSources.process_subset`](@ref): fetch data from server,
write a raster `.tif` file.

The MODIS API only allows requests for ten or less dates.

Returns the filepath/s of the downloaded or pre-existing files.
"""
function _getrasterchunk(T::Type{<:ModisProduct}, layer::Int;
    dates::Vector{String},
    kwargs...
)
    length(dates) > 10 && throw("Too many dates provided. Use from and to arguments")

    df = modis_request(
        T, list_layers(T)[layer], kwargs[:lat], kwargs[:lon], kwargs[:km_ab], kwargs[:km_lr], dates[1], dates[end]
    )

    out = process_subset(T, df)

    return out
end

function rasterpath(T::Type{<:ModisProduct}, layer; kwargs...)
    # argument checks
    check_layers(T, layer)
    check_kwargs(T; kwargs...)
    return joinpath(_rasterpath(T, layer), rastername(T; kwargs...))
end

function _rasterpath(T::Type{<:ModisProduct})
    return joinpath(rasterpath(), "MODIS", string(nameof(T)))
end

function _rasterpath(T::Type{<:ModisProduct}, layer::Int)
    return joinpath(_rasterpath(T), list_layers(T)[layer])
end

function _rasterpath(T::Type{<:ModisProduct}, layer::Symbol)
    return joinpath(_rasterpath(T), list_layers(T)[modis_int(T, layer)])
end

function _rasterpath(T::Type{<:ModisProduct}, layer::String)
    layer in list_layers(T) && (return joinpath(_rasterpath(T), layer))
    throw("Unknow layer in product $(string(T))")
end

function rastername(T::Type{<:ModisProduct}; kwargs...)
    check_kwargs(T; kwargs...)
    name = "$(round(kwargs[:lat], digits = 4))_$(round(kwargs[:lon], digits = 4))_$(kwargs[:date]).tif"
    return name
end

date_step(T::Type{<:ModisProduct}) = Day(16)
date_step(T::Type{MODIS{X}}) where X = date_step(X)




