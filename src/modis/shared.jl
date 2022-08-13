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

- `from` and `to`: `String` or `Date` in format YYYY-MM-DD for required start and end dates of raster download. Will download several files, one for each date.

Returns the filepath/s of the downloaded or pre-existing files.
"""
function getraster(T::Type{<:ModisProduct}, layer::Union{Tuple, Symbol, Int}=layerkeys(T);
    lat::Real,
    lon::Real,
    km_ab::Int,
    km_lr::Int,
    from::Union{String, Date},
    to::Union{String, Date}
)
    _getraster(T, layer;
        lat = lat,
        lon = lon,
        km_ab = km_ab,
        km_lr = km_lr,
        from = from,
        to = to
    )
end

# if layer is a tuple, get them all using _map_layers
function _getraster(T::Type{<:ModisProduct}, layers::Tuple; kwargs...)
    _map_layers(T, layers; kwargs...)
end

# convert layer symbols to int
function _getraster(T::Type{<:ModisProduct}, layer::Symbol; kwargs...)
    _getraster(T, modis_int(T, layer); kwargs...)
end

function _getraster(T::Type{<:ModisProduct}, layer::Int;
    lat::Real,
    lon::Real,
    km_ab::Int,
    km_lr::Int,
    from::Union{String, Date},
    to::Union{String, Date}
)
    dates = list_dates(T;
        lat = lat,
        lon = lon,
        format = "ModisDate",
        from = from,
        to = to
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

function rastername(T::Type{<:ModisProduct}, layer::Int; kwargs...)
    name = "$(layerkeys(T)[layer])_$(kwargs[:lat])_$(kwargs[:lon])_$(kwargs[:date]).tif"
    return name
end

function rastername(T::Type{<:ModisProduct}; kwargs...)
    name = "$(round(kwargs[:lat], digits = 4))_$(round(kwargs[:lon], digits = 4))_$(kwargs[:date]).tif"
    return name
end




