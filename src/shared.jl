# Vector layers are allowed, but converted to `Tuple` immediatedly.
function getraster(T::Type, layers::AbstractArray; kw...)
    getraster(T, (layers...,); kw...)
end
# Without a layers argument, all layers are downloaded
getraster(T::Type; kw...) = getraster(T, layers(T); kw...)

"""
    getraster_keywords(::Type{<:RasterDataSource})

Trait for defining data source keywords, which returns
a `NTuple{N,Symbol}`.

The default fallback method returns `()`.
"""
getraster_keywords(::Type{<:RasterDataSource}) = ()

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

function _format(T::Type{<:RasterDataSource}, date::TimeType)
    daterange = date_range(T)
    datestep = date_step(T)
    # check if the date is within the range
    if date < first(daterange) || date > last(daterange)
        _date_error(date, daterange)
    end

    # find which bin it is in
    r = range(daterange...; step = datestep)
    idx = searchsortedfirst(r, date, lt = <=)

    # from here on just use integer math
    startyear = Dates.year(first(daterange))
    yearstep = Dates.value(datestep)
    startyear = startyear + yearstep * (idx - 2)
    endyear = startyear + yearstep - 1
    return "$startyear-$endyear"
end

function _date_error(date, daterange)
    startyear = Dates.year(first(daterange))
    endyear = Dates.year(last(daterange))
    error("The requested dataset covers the period from $startyear-$endyear, which does not include $date")
end         

function _maybe_download(uri::URI, filepath, headers = []; update::Bool=false)
    if update || !isfile(filepath)
        mkpath(dirname(filepath))
        @info "Starting download for $uri"
        try
            download(string(uri), filepath; headers)
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

# Tiled sources define `_tiles(T, args..., extent; kw...)`, the tiles covering `extent`,
# `_has_tile(T, args..., tile; kw...)`, and operations on one tile, e.g. `_getraster(T, args..., tile; kw...)`.
# `_tiled` applies an operation to a tile, an array of tiles, or the tiles covering an extent.
# Without a selection `_rasterpath` gives the folder holding the tiles.
function _rasterpath end

function _tile_selection(; bounds=nothing, extent=nothing, tile_index=nothing)
    count(!isnothing, (bounds, extent, tile_index)) > 1 &&
        throw(ArgumentError("Pass only one of `extent`, `bounds` or `tile_index`"))
    something(extent, bounds, tile_index, Some(nothing))
end

_tiled(f, ::Nothing, T, args...; kw...) = throw(ArgumentError("`extent` must be specified"))
_tiled(::typeof(_rasterpath), ::Nothing, T, args...; kw...) = _rasterpath(T, args...; kw...)
_tiled(f, extent::Union{Extents.Extent,Tuple}, T, args...; kw...) =
    _tiled(f, _tiles(T, args..., extent; kw...), T, args...; kw...)
_tiled(f, tiles::AbstractArray, T, args...; kw...) =
    map(tile -> _has_tile(T, args..., tile; kw...) ? f(T, args..., tile; kw...) : missing, tiles)
_tiled(f, tile, T, args...; kw...) = f(T, args..., tile; kw...)

_check_order((a, b)) = a > b && throw(ArgumentError("Upper bound $b less than lower bound $a"))

_check_depth(T, depth) = depth in depths(T) || throw(ArgumentError(
    "Depth \"$depth\" is not valid. Valid depths: $(join(depths(T), ", "))"
))
_check_component(T, component) = component in components(T) || throw(ArgumentError(
    "Component \"$component\" is not valid. Valid components: $(join(components(T), ", "))"
))

# fallback for _format
_format(::Type, T) = _format(T)
_format(T::Type) = string(nameof(T))
_format(M::Type{<:ClimateModel}) = replace(string(nameof(M)), "_" => "-")
