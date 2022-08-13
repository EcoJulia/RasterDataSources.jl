"""
    MODIS-specific utility functions

MODIS data is not available in .tif format so we need a bit more
steps before storing the retrieved data and we can't download() it.

Data parsing is way easier using JSON.jl and DataFrames.jl but it
adds more dependencies..
"""

"""
    Convert layer key Symbol to integer
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
    Lowest level function for requests to modis server.

All arguments are assumed of correct types
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
    Convert x and y in sinusoidal projection to lat and lon in dec. degrees

The EPSG.io API (https://github.com/maptiler/epsg.io) takes care of coordinate
conversions. This is not ideal in terms of network use but at least the
coordinates are correct.
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
    Process a raw subset dataframe and create several rasters

For each band, a separate folder is created, containing a file for each of
the required dates. This is inspired by the way WorldClim{Climate} treats the
problem of possibly having to download several dates AND bands.
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

    raster_path = rasterpath(T)

    path_out = String[]

    for d in eachindex(dates)

        raster_name = rastername(T;
            lat = gt[4],
            lon = gt[1],
            date = dates[d]
        )

        ar = Array{Float64}(undef, nrows, ncols, length(bands))
        
        for b in eachindex(bands)

            sub_df = subset(df,
                :calendar_date => x -> x .== dates[d],
                :band => y -> y .== bands[b]
            )
            
            mat = Matrix{Float64}(undef, nrows, ncols)

            filepath = joinpath(raster_path, bands[b], raster_name)

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

            push!(path_out, joinpath(raster_path, bands[b], raster_name))

        end
    end

    return (length(path_out) == 1 ? path_out[1] : path_out)
end