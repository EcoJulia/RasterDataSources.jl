"""
    MODIS-specific utility functions

MODIS data is not available in .tif format so we need a bit more
steps before storing the retrieved data and we can't download() it.

Data parsing is way easier using JSON.jl and DataFrames.jl but it
adds more dependencies..
"""

"""
    modis_int(T::Type{<:ModisProduct}, l::Symbol)

Converts Symbol `l` to the corresponding integer if `l` is in the
layer keys of the required `ModisProduct` `T`.
"""
function modis_int(T::Type{<:ModisProduct}, l::Symbol)
    keys = layerkeys(T)
    for i in eachindex(keys)
        keys[i] === l && return(i)
    end 
end

"""
    MODIS API address
"""
const MODIS_URI = URI(
    scheme = "https",
    host = "modis.ornl.gov",
    path = "/rst/api/v1"
)

"""
    modis_request(T::Type{<:ModisProduct}, args...)

Lowest level function for requests to modis server. All arguments are assumed of correct types

# Arguments

 - `layer`: `String` matching the "exact" layer name (i.e. as it is written in the MODIS dataset itself) for the given product. e.g. `"250m_16_days_EVI"`.

 - `lat`, `lon`, `km_ab`, `km_lr` in correct types

 - `from`, `to`: `String`s of astronomical dates for start and end dates of downloaded data, e.g. `"A2002033"` for "2002-02-02"

Returns a `DataFrame` with all requested data directly downloaded from MODIS. The `DataFrame` will almost always directly be passed to [`RasterDataSources.process_subset`](@ref)
"""
function modis_request(
    T::Type{<:ModisProduct},
    layer,
    lat,
    lon,
    km_ab,
    km_lr,
    from,
    to
)
    # using joinpath here is more readable but works only for UNIX based OS, :'(
    base_uri = join([string(MODIS_URI), product(T), "subset"], "/")
    query = string(URI(; query = Dict(
        "latitude" => string(lat),
        "longitude" => string(lon),
        "startDate" => string(from),
        "endDate" => string(to),
        "kmAboveBelow" => string(km_ab),
        "kmLeftRight" => string(km_lr),
        "band" => string(layer)
    )))

    r = HTTP.request(
        "GET",
        URI(base_uri * query),
        ["Accept" => "application/json"]
    )

    body = JSON.parse(String(r.body))

    # The server outputs data in a nested JSON array that we can
    # parse manually : the highest level is a metadata array with
    # a "subset" column containing pixel array for each (band, timepoint)

    metadata = DataFrame(body)[:, Not(:subset)]

    out = DataFrame()

    for i in 1:nrow(metadata) # for each (band, time)

        subset = DataFrame(body["subset"][i])
        n = nrow(subset)
        subset.pixel = 1:n

        # this thing here could be prettier..
        subset.cellsize = repeat([metadata[i, :cellsize]], n)
        subset.latitude = repeat([metadata[i, :latitude]], n)
        subset.longitude = repeat([metadata[i, :longitude]], n)
        subset.ncols  = repeat([metadata[i, :ncols]], n)
        subset.nrows = repeat([metadata[i, :nrows]], n)
        subset.xllcorner = repeat([metadata[i, :xllcorner]], n)
        subset.yllcorner = repeat([metadata[i, :yllcorner]], n)
        subset.header = repeat([metadata[i, :header]], n)

        out = [out; subset]
    end

    return out
end
 
"""
    sin_to_ll(x::Real, y::Real)    

Convert x and y in sinusoidal projection to lat and lon in dec. degrees

The ![EPSG.io API](https://github.com/maptiler/epsg.io) takes care of coordinate conversions. This is not ideal in terms of network use but guarantees that the coordinates are correct.
"""
function sin_to_ll(x::Real, y::Real)

    url = "https://epsg.io/trans"

    @info "Asking EPSG.io for coordinates calculation"

    query = Dict(
        "x" => string(x),
        "y" => string(y),
        "s_srs" => "53008", # sinusoidal
        "t_srs" => "4326" # WGS84
    )

    r = HTTP.request(
        "GET",
        url;
        query = query
    )

    body = JSON.parse(String(r.body))

    lat = parse(Float64, body["y"])
    lon = parse(Float64, body["x"])

    return (lat, lon)
end

# data from https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html
const EARTH_EQ_RADIUS = 6378137
const EARTH_POL_RADIUS = 6356752

function meters_to_latlon(d::Real, lat::Real)
    dlon = asind(d/(cosd(lat)*EARTH_EQ_RADIUS))
    dlat = d * 180 / (π * EARTH_POL_RADIUS)

    return (dlat, dlon)
end

function maybe_build_gt(
    xllcorner::Real,
    yllcorner::Real,
    nrows::Int,
    cellsize::Real
)
    filepath = joinpath(
        rasterpath(),
        "MODIS",
        "geotransforms",
        string(xllcorner) * "," * string(yllcorner) * "," * string(cellsize) * "," *string(nrows) * ".csv"
    )

    if isfile(filepath)
        gt_str = open(filepath) do f
            readline(f)
        end
        gt = parse.(Float64, split(gt_str, ","))
    else ## Build geotransform : modis provides lower-left corner 
        # coordinates in sin projection ; we want upper-left in WGS84

        # convert coordinates
        lat, lon = sin_to_ll(xllcorner, yllcorner)

        # convert cell size in meters to degress in lat and lon directions
        resolution = meters_to_latlon(
            cellsize,
            lat
        ) # watch out, this is a Tuple{Float64, Float64}

        # build the geotransform 
        # (https://yeesian.com/ArchGDAL.jl/stable/quickstart/#Dataset-Georeferencing)

        gt = [
            lon - resolution[2]/2, # left longitude
            resolution[2], # lon resolution in degrees
            0.0, # no rotation
            lat + nrows*resolution[1] + resolution[1]/2, # up latitude
            0.0, # no rotation (yes, this order)
            -resolution[1] # lat resolution in degrees, negative because the data
            # matrix is south-up oriented
        ]

        # store gt

        gt_str = join(string.(gt), ",")
        mkpath(dirname(filepath))
        open(filepath, "w") do f
            write(f, gt_str)
        end
    end

    return gt
end

"""
    process_subset(T::Type{<:ModisProduct}, df::DataFrame)    

Process a raw subset dataframe and create several raster files. Any already existing file is not overwritten.

For each band, a separate folder is created, containing a file for each of the required dates. This is inspired by the way WorldClim{Climate} treats the problem of possibly having to download several dates AND bands.

Can theoretically be used for `DataFrame`s of MODIS data that do not directly come from [`RasterDataSources.modis_request`](@ref), but caution is advised.

Returns the filepath/s of the created or pre-existing files.
"""
function process_subset(T::Type{<:ModisProduct}, df::DataFrame)
    
    dates = unique(df[:, :calendar_date])
    bands = unique(df[:, :band])

    ncols = df[1, :ncols]
    nrows = df[1, :nrows]

    cellsize = df[1, :cellsize]

    xllcorner = parse(Float64, df[1, :xllcorner])
    yllcorner = parse(Float64, df[1, :yllcorner])

    gt = maybe_build_gt(xllcorner, yllcorner, nrows, cellsize)

    path_out = String[]

    for d in eachindex(dates)

        ar = Array{Float64}(undef, nrows, ncols, length(bands))
        
        for b in eachindex(bands)

            sub_df = subset(df,
                :calendar_date => x -> x .== dates[d],
                :band => y -> y .== bands[b]
            )
            
            mat = Matrix{Float64}(undef, nrows, ncols)

            filepath = rasterpath(T, bands[b];
                lat = gt[4],
                lon = gt[1],
                date = dates[d]
            )

            # fill matrix row by row
            count = 1
            for j in 1:ncols
                for i in 1:nrows
                    mat[i,j] = float(sub_df[count, :data])
                    count += 1
                end
            end

            ar[:,:,b] = mat

            mkpath(dirname(filepath))

            if !isfile(filepath)
                @info "Creating raster file $(basename(filepath)) in $(dirname(filepath))"
                ArchGDAL.create(
                    filepath,
                    driver = ArchGDAL.getdriver("GTiff"),
                    width = ncols,
                    height = nrows,
                    nbands = 1,
                    dtype = Float32
                ) do dataset
                    # add data to object
                    ArchGDAL.write!(dataset, mat, 1)
                    # set geotransform
                    ArchGDAL.setgeotransform!(dataset, gt)
                    # set crs
                    ArchGDAL.setproj!(dataset, ArchGDAL.toWKT(
                        ArchGDAL.importPROJ4("+proj=latlong +ellps=WGS84 +datum=WGS84 +no_defs"))
                    )
                end
            else
                @info "Raster file $(basename(filepath)) already exists in $(dirname(filepath))"
            end

            push!(path_out, filepath)

        end
    end

    return (length(path_out) == 1 ? path_out[1] : path_out)
end

"""
    check_layers(T::Type{<:ModisProduct}, layers::Union{Tuple, AbstractVector, Symbol, String, Int}) => nothing

Checks if required layers make sense for the MODIS product T.
"""
function check_layers(T::Type{<:ModisProduct}, layers::Union{Tuple, AbstractVector, Symbol, String, Int})
    if typeof(layers) <: Tuple || typeof(layers) <: AbstractVector
        for l in layers
            _check_layer(T::Type{<:ModisProduct}, l)
        end
    else
        _check_layer(T::Type{<:ModisProduct}, layers)
    end
end

function _check_layer(T::Type{<:ModisProduct}, layer::Symbol)
    !(layer in layerkeys(T)) && throw(ArgumentError(
        "Invalid layer $layer for product $T.\nAvailable layers are $(layerkeys(T))"
    ))
    return nothing
end

function _check_layer(T::Type{<:ModisProduct}, layer::Int)
    !(layer in layers(T)) && throw(ArgumentError(
        "Invalid layer $layer for product $T.\nAvailable layers are $(layers(T))"
    ))
    return nothing
end

function _check_layer(T::Type{<:ModisProduct}, layer::String)
    !(layer in list_layers(T)) && throw(ArgumentError(
        "Invalid layer $layer for product $T.\nAvailable layers are $(list_layers(T)).\nProceed with caution while using `String` layers. You might want to use their `Symbol` counterparts."
    ))
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
        (kwargs[:lat] < -90 || kwargs[:lat] > 90) && push!(
            errors,
            "Latitude lat=$(kwargs[:lat]) must be between -90 and 90."
        )
    end

    # check lon
    if :lon in symbols
        (kwargs[:lon] < -180 || kwargs[:lon] > 180) && push!(
            errors,
            "Longitude lon=$(kwargs[:lon]) must be between -180 and 180."
        )
    end

    # check km_ab
    if :km_ab in symbols
        (kwargs[:km_ab] < 0 || kwargs[:km_ab] > 100) && push!(
            errors,
            "Km above and below km_ab=$(kwargs[:km_ab]) must be between 0 and 100."
        )
    end

    # check km_lr
    if :km_lr in symbols
        (kwargs[:km_lr] < 0 || kwargs[:km_lr] > 100) && push!(
            errors,
            "Km left and right km_lr=$(kwargs[:km_lr]) must be between 0 and 100."
        )
    end

    # check from
    if :from in symbols
        # check if conversion works
        from = Date(kwargs[:from])
        (from < Date(2000) || from > Dates.now()) && push!(
            errors,
            "Unsupported date for from=$(from)"
        )
    end

    # check to
    if :to in symbols
        # check if conversion works
        to = Date(kwargs[:to])
        (to < Date(2000) || to > Dates.now()) && push!(
            errors,
            "Unsupported date for to=$(to)"
        )
    end

    if length(errors) > 0
        if length(errors) == 1
            throw(ArgumentError(errors[1]))
        else
            throw(ArgumentError(
                join(["Several wrong arguments.";errors], "\n")
            ))
        end
    end

    return nothing
end