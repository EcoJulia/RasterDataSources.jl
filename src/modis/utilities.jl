"""
    MODIS-specific utility functions

MODIS data is not available in .tif format so we need a bit more
steps before storing the retrieved data and we can't download() it.

Data parsing is way easier using JSON.jl but it adds a dependency
"""

"""
    modis_int(T::Type{<:ModisProduct}, l::Symbol)

Converts Symbol `l` to the corresponding integer if `l` is in the
layer keys of the required `ModisProduct` `T`.
"""
function modis_int(T::Type{<:ModisProduct}, l::Symbol)
    keys = layerkeys(T)
    for i in eachindex(keys)
        keys[i] === l && return (i)
    end
end

"""
    MODIS API address
"""
const MODIS_URI = URI(scheme = "https", host = "modis.ornl.gov", path = "/rst/api/v1")

"""
    modis_request(T::Type{<:ModisProduct}, args...)

Lowest level function for requests to modis server. All arguments are assumed correct.

# Arguments

 - `layer`: `String` matching the "exact" layer name (i.e. as it is written in the MODIS dataset itself) for the given product. e.g. `"250m_16_days_EVI"`.

 - `lat`, `lon`, `km_ab`, `km_lr` in correct types

 - `from`, `to`: `String`s of astronomical dates for start and end dates of downloaded data, e.g. `"A2002033"` for "2002-02-02"

Returns a `NamedTuple` of information relevant to build a raster header, and a `Vector` of `Dict`s containing raster data, directly downloaded from MODIS. Those will almost always directly be passed to [`RasterDataSources.process_subset`](@ref)
"""
function modis_request(T::Type{<:ModisProduct}, layer, lat, lon, km_ab, km_lr, from, to)
    # using joinpath here is more readable but works only for UNIX based OS, :'(
    base_uri = join([string(MODIS_URI), product(T), "subset"], "/")
    query = string(
        URI(;
            query = Dict(
                "latitude" => string(lat),
                "longitude" => string(lon),
                "startDate" => string(from),
                "endDate" => string(to),
                "kmAboveBelow" => string(km_ab),
                "kmLeftRight" => string(km_lr),
                "band" => string(layer),
            ),
        ),
    )

    r = HTTP.request("GET", URI(base_uri * query), ["Accept" => "application/json"])

    body = JP.parse(String(r.body))

    # The server outputs data in a nested JSON array that we can
    # parse manually : the highest level is a metadata array with
    # a "subset" column containing pixel array for each (band, timepoint)

    # the header information is in the top-level of the request
    pars = (
        nrows = body["nrows"],
        ncols = body["ncols"],
        xll = body["xllcorner"],
        yll = body["yllcorner"],
        cellsize = body["cellsize"]
    )

    # data is in the subset field
    subset = body["subset"]

    return subset, pars
end

"""
    sinusoidal_to_latlon(x::Real, y::Real)    

Convert x and y in sinusoidal projection to lat and lon in dec. degrees

The ![EPSG.io API](https://github.com/maptiler/epsg.io) takes care of coordinate conversions. This is not ideal in terms of network use but guarantees that the coordinates are correct.
"""
function sinusoidal_to_latlon(x::Real, y::Real)

    url = "https://epsg.io/trans"

    @info "Asking EPSG.io for coordinates calculation"

    query = Dict(
        "x" => string(x),
        "y" => string(y),
        "s_srs" => "53008", # sinusoidal
        "t_srs" => "4326", # WGS84
    )

    r = HTTP.request("GET", url; query = query)

    body = JP.parse(String(r.body))

    lat = parse(Float64, body["y"])
    lon = parse(Float64, body["x"])

    return (lat, lon)
end

# data from https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
const EARTH_EQ_RADIUS = 6378137
const EARTH_POL_RADIUS = 6356752

function meters_to_latlon(d::Real, lat::Real)
    dlon = asind(d / (cosd(lat) * EARTH_EQ_RADIUS))
    dlat = d * 180 / (π * EARTH_POL_RADIUS)

    return (dlat, dlon)
end

function _maybe_prepare_params(xllcorner::Real, yllcorner::Real, nrows::Int, cellsize::Real)
    filepath = joinpath(
        rasterpath(),
        "MODIS",
        "headers",
        string(xllcorner) *
        "," *
        string(yllcorner) *
        "," *
        string(cellsize) *
        "," *
        string(nrows) *
        ".csv",
    )

    if isfile(filepath)
        pars_str = open(filepath, "r") do f
            readline(f)
        end
        pars = parse.(Float64, split(pars_str, ","))
    else
        # coordinates in sin projection ; we want upper-left in WGS84
        # convert coordinates
        yll, xll = sinusoidal_to_latlon(xllcorner, yllcorner)

        # convert cell size in meters to degrees in lat and lon directions
        dy, dx = meters_to_latlon(cellsize, yll) # watch out, this is a Tuple{Float64, Float64}

        pars = [xll, yll, dx, dy]
        # store in file
        pars_str = join(string.(pars), ",")
        mkpath(dirname(filepath))
        open(filepath, "w") do f
            write(f, pars_str)
        end
    end

    # return a NamedTuple
    return (xll = pars[1], yll = pars[2], dx = pars[3], dy = pars[4])
end

"""
    process_subset(T::Type{<:ModisProduct}, subset::Vector{Any}, pars::NamedTuple)    

Process a raw subset and argument parameters and create several raster files. Any already existing file is not overwritten.

For each band, a separate folder is created, containing a file for each of the required dates. This is inspired by the way WorldClim{Climate} treats the problem of possibly having to download several dates AND bands.

Can theoretically be used for MODIS data that does not directly come from [`RasterDataSources.modis_request`](@ref), but caution is advised.

Returns the filepath/s of the created or pre-existing files.
"""
function process_subset(T::Type{<:ModisProduct}, subset::Vector{Any}, pars::NamedTuple)

    # coerce parameters from String to correct types
    ncols = pars[:ncols]
    nrows = pars[:nrows]

    cellsize = pars[:cellsize]

    xll = parse(Float64, pars[:xll])
    yll = parse(Float64, pars[:yll])

    pars = _maybe_prepare_params(xll, yll, nrows, cellsize)

    path_out = String[]

    for i in eachindex(subset) # for each (date, band)
        date = subset[i]["calendar_date"]
        band = subset[i]["band"]

        filepath = rasterpath(T, band; lat = pars[:yll], lon = pars[:xll], date = date)
        
        mat = permutedims(reshape(subset[i]["data"], (ncols, nrows)))

        mkpath(dirname(filepath)) # prepare directories if they dont exist

        if !isfile(filepath)
            @info "Creating raster file $(basename(filepath)) in $(dirname(filepath))"
            write_ascii(filepath, mat; ncols = ncols, nrows = nrows, nodatavalue = -3000.0, pars...)
        else
            @info "Raster file $(basename(filepath)) already exists in $(dirname(filepath))"
        end

        push!(path_out, filepath)

    end

    return (length(path_out) == 1 ? path_out[1] : path_out)
end

"""
    check_layers(T::Type{<:ModisProduct}, layers::Union{Tuple, AbstractVector, Symbol, String, Int}) => nothing

Checks if required layers make sense for the MODIS product T.
"""
function check_layers(
    T::Type{<:ModisProduct},
    layers::Union{Tuple,AbstractVector,Symbol,String,Int},
)
    if typeof(layers) <: Tuple || typeof(layers) <: AbstractVector
        for l in layers
            _check_layer(T::Type{<:ModisProduct}, l)
        end
    else
        _check_layer(T::Type{<:ModisProduct}, layers)
    end
end

function _check_layer(T::Type{<:ModisProduct}, layer::Symbol)
    !(layer in layerkeys(T)) && throw(
        ArgumentError(
            "Invalid layer $layer for product $T.\nAvailable layers are $(layerkeys(T))",
        ),
    )
    return nothing
end

function _check_layer(T::Type{<:ModisProduct}, layer::Int)
    !(layer in layers(T)) && throw(
        ArgumentError(
            "Invalid layer $layer for product $T.\nAvailable layers are $(layers(T))",
        ),
    )
    return nothing
end

function _check_layer(T::Type{<:ModisProduct}, layer::String)
    !(layer in list_layers(T)) && throw(
        ArgumentError(
            "Invalid layer $layer for product $T.\nAvailable layers are $(list_layers(T)).\nProceed with caution while using `String` layers. You might want to use their `Symbol` counterparts.",
        ),
    )
end

"""
    check_kwargs(T::Type{ModisProduct}; kwargs...) => nothing

"Never trust user input". Checks all keyword arguments that might be used in internal calls.
"""
function check_kwargs(T::Type{<:ModisProduct}; kwargs...)
    symbols = keys(kwargs)
    errors = String[]

    # check lat
    if :lat in symbols
        (kwargs[:lat] < -90 || kwargs[:lat] > 90) &&
            push!(errors, "Latitude lat=$(kwargs[:lat]) must be between -90 and 90.")
    end

    # check lon
    if :lon in symbols
        (kwargs[:lon] < -180 || kwargs[:lon] > 180) &&
            push!(errors, "Longitude lon=$(kwargs[:lon]) must be between -180 and 180.")
    end

    # check km_ab
    if :km_ab in symbols
        (kwargs[:km_ab] < 0 || kwargs[:km_ab] > 100) && push!(
            errors,
            "Km above and below km_ab=$(kwargs[:km_ab]) must be between 0 and 100.",
        )
    end

    # check km_lr
    if :km_lr in symbols
        (kwargs[:km_lr] < 0 || kwargs[:km_lr] > 100) && push!(
            errors,
            "Km left and right km_lr=$(kwargs[:km_lr]) must be between 0 and 100.",
        )
    end

    # check from
    if :from in symbols
        # check if conversion works
        from = Date(kwargs[:from])
        (from < Date(2000) || from > Dates.now()) &&
            push!(errors, "Unsupported date for from=$(from)")
    end

    # check to
    if :to in symbols
        # check if conversion works
        to = Date(kwargs[:to])
        (to < Date(2000) || to > Dates.now()) &&
            push!(errors, "Unsupported date for to=$(to)")
    end

    if :date in symbols
        _check_date(kwargs[:date]) ||
            push!(errors, "Unsupported date(s) in date=$(kwargs[:date])")
    end

    if length(errors) > 0
        if length(errors) == 1
            throw(ArgumentError(errors[1]))
        else
            throw(ArgumentError(join(["Several wrong arguments."; errors], "\n")))
        end
    end

    return nothing
end

_check_date(d::AbstractVector) = all(b -> b == true, map(_check_date, d))
_check_date(d::Tuple) = all(b -> b == true, map(_check_date, d))
_check_date(d::String) = _check_date(Date(d))
"""
    _check_date(d::Dates.TimeType)

Does not check if `d` is available, only checks if `d` makes sense, i.e if `d` **could** be available.

Returns `true` for good dates, `false` for bad ones.
"""
function _check_date(d::Dates.TimeType)
    return !(d < Date(2000) || d > Dates.now())
end
