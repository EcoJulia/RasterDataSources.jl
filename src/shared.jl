"""
    getraster(T::Type, layers::Union{Tuple,Int,Symbol}; kw...)

Download raster layers `layers` from the data source `T`,
returning a `String` for a single layer, or a `NamedTuple`
for a `Tuple` of layers. `layer` values are usually values of
`Symbol`, but can also be `Int` for `BioClim` datasets.

Keyword arguments depend on the specific data source. 
The may modify the return value, following a pattern:
- `month` keywords of `AbstractArray will return a `Vector{String}`
    or `Vector{<:NamedTuple}`.
- `date` keywords of `AbstractArray` will return a `Vector{String}` or
    `Vector{<:NamedTuple}`.
- `date` keywords of `Tuple{start,end}` will take all the dates between the 
    start and end dates, and also return `Vector{String}` or `Vector{<:NamedTuple}`.


Where `date` and `month` keywords coexist, `Vector{Vector{String}}` of
`Vector{Vector{NamedTuple}}` is the result. `date` ranges are always
the outer `Vector`, `month` the inner `Vector` with `layer` tuples as
the inner `NamedTuple`. No other keywords can be `Vector`.

This schema may be added to in future for datasets with additional axes,
but should not change for the existing `RasterDataSource` types.
"""
function getraster end
# Vector layers are allowed, but converted to `Tuple` immediatedly.
function getraster(T::Type, layers::AbstractArray; kw...)
    getraster(T, (layers...,); kw...)
end
# Without a layers argument, all layers are downloaded
getraster(T::Type; kw...) = getraster(T, layers(T); kw...)

# Default assumption for `layerkeys` is that the layer
# is the same as the layer key. This is not the case for
# e.g. BioClim, where layers can be specified with Int.
layerkeys(T::Type) = layers(T)
layerkeys(T::Type, layers) = layers

has_matching_layer_size(T) = true
has_constant_dims(T) = true
has_constant_metadata(T) = true

date_sequence(T::Type, dates; kw...) = date_sequence(date_step(T), dates)
date_sequence(step, date) = _date_sequence(step, date)

_date_sequence(step, dates::AbstractArray) = dates
_date_sequence(step, dates::NTuple{2}) = first(dates):step:last(dates)
_date_sequence(step, date) = date:step:date

function _maybe_download(uri::URI, filepath, headers = [])
    if !isfile(filepath)
        mkpath(dirname(filepath))
        @info "Starting download for $uri"
        try
            HTTP.download(string(uri), filepath, headers)
        catch e
            # Remove anything that was downloaded before the error
            isfile(filepath) && rm(filepath)
            throw(e)
        end
    end
    filepath
end

function rasterpath()
    if haskey(ENV, "RASTERDATASOURCES_PATH") && isdir(ENV["RASTERDATASOURCES_PATH"])
        ENV["RASTERDATASOURCES_PATH"]
    else
        error("You must set `ENV[\"RASTERDATASOURCES_PATH\"]` to a path in your system")
    end
end

function delete_rasters()
    # May need an "are you sure"? - this could be a lot of GB of data to lose
    ispath(rasterpath()) && rm(rasterpath())
end

function delete_rasters(T::Type)
    ispath(rasterpath(T)) && rm(rasterpath(T))
end

_check_res(T, res) =
    res in resolutions(T) || throw(ArgumentError("Resolution $res not in $(resolutions(T))"))
_check_layer(T, layer) =
    layer in layers(T) || throw(ArgumentError("Layer $layer not in $(layers(T))"))

_date2string(t, date) = Dates.format(date, _dateformat(t))
_string2date(t, d::AbstractString) = Date(d, _dateformat(t))

# Inner map over layers Tuple - month/date maps earlier
# so we get Vectors of NamedTuples of filenames
function _map_layers(T, layers, args...; kw...)
    filenames = map(layers) do l
        _getraster(T, l, args...; kw...)
    end
    keys = layerkeys(T, layers)
    return NamedTuple{keys}(filenames)
end
