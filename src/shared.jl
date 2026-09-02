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

Only lists the source-specific keywords. `update`, which is accepted by every
`getraster` method, is not included.

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

"""
    _resolve_tiles(T::Type, selection; kw...)

Convert a spatial `selection` (bounds, extent, or an already-resolved tile
identifier) into tiles. The default assumes a regular grid addressed by
`CartesianIndex`, using `bounds_to_tile_indices(T, selection)`; datasets on an
irregular grid (e.g. `SoilGrids`) add their own method.
"""
_resolve_tiles(::Type, i::CartesianIndex; kw...) = i
_resolve_tiles(::Type, indices::CartesianIndices; kw...) = indices
_resolve_tiles(T::Type, selection; kw...) = bounds_to_tile_indices(T, selection)

"""
    _apply_tiles(primitive, exists, tiles)

Apply `primitive` (a 1-argument function of a tile) to `tiles`, returning
`missing` for tiles that fail `exists`. A single tile (e.g. `CartesianIndex`)
is applied directly, with no `exists` check; an `AbstractArray` of tiles
(`CartesianIndices`, or a plain `Vector` for an irregular grid) is mapped over,
preserving its shape.
"""
_apply_tiles(primitive, exists, tile) = primitive(tile)
_apply_tiles(primitive, exists, tiles::AbstractArray) =
    map(tile -> exists(tile) ? primitive(tile) : missing, tiles)

"""
    _dispatch_tiles(op, primitive, exists, directory, T, selection; missing_selection_error, resolve_kw...)

Shared dispatch for tiled datasets: if `selection` is `nothing`, `getraster`
throws `missing_selection_error` and every other op returns `directory`;
otherwise `selection` is resolved to tiles via `_resolve_tiles(T, selection;
resolve_kw...)` and `primitive` applied to each with `_apply_tiles`.
"""
function _dispatch_tiles(op::Symbol, primitive, exists, directory, T, selection;
        missing_selection_error="A spatial selector must be provided", resolve_kw...)
    if isnothing(selection)
        op === :getraster && throw(ArgumentError(missing_selection_error))
        return directory
    end
    tiles = _resolve_tiles(T, selection; resolve_kw...)
    return _apply_tiles(primitive, exists, tiles)
end

"""
    _dispatch_regular_tiles(op, primitive, exists, directory, T; bounds, extent, tile_index)

`_dispatch_tiles` for datasets addressed by `CartesianIndex` on a regular grid
(`SRTM`, `CopernicusDEM`): exactly one of `bounds`/`extent`/`tile_index` must
be given. `primitive(T, tile_index)` is the per-tile operation.
"""
function _dispatch_regular_tiles(op::Symbol, primitive, exists, directory, T;
        bounds=nothing, extent=nothing, tile_index=nothing)
    n_set = !isnothing(bounds) + !isnothing(extent) + !isnothing(tile_index)
    n_set > 1 && throw(ArgumentError("Pass only one of `extent`, `bounds` or `tile_index`"))
    selection = n_set == 0 ? nothing : something(extent, bounds, tile_index)
    _dispatch_tiles(op, i -> primitive(T, i), exists, directory, T, selection;
        missing_selection_error="One of `extent`, `bounds` or `tile_index` kwarg must be specified")
end

# fallback for _format
_format(::Type, T) = _format(T)
_format(T::Type) = string(nameof(T))
_format(M::Type{<:ClimateModel}) = replace(string(nameof(M)), "_" => "-")
