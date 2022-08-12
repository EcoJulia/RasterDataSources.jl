"""
    MODIS{ModisProduct} <: RasterDataSource

MODIS/VIIRS Land Product Database. Vegetation indices, surface reflectance, and more land cover data.

See [modis.ornl.gov](https://modis.ornl.gov/)
"""
struct MODIS{X} <: RasterDataSource end

const MODIS_URI = URI(
    scheme = "https",
    host = "modis.ornl.gov",
    path = "/rst/api/v1"
)

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

function getraster(T::Type{<:ModisProduct}, layer::Union{Tuple, Symbol, Int};
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

        files = map(chunks) do c
            length(c) > 0 && _getrasterchunk(T, layer;
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

# this should always receive less than 10 dates
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

function rasterpath(T::Type{<:ModisProduct})
    return joinpath(rasterpath(), "MODIS", string(nameof(T)))
end

function rastername(T::Type{<:ModisProduct}, layer::Int; kwargs...)
    name = "$(layerkeys(T)[layer])_$(kwargs[:lat])_$(kwargs[:lon])_$(kwargs[:date]).tif"
    return name
end

function rastername(T::Type{<:ModisProduct}; kwargs...)
    name = "$(round(kwargs[:lat], digits = 4))_$(round(kwargs[:lon], digits = 4))_$(kwargs[:date]).tif"
    return name
end




