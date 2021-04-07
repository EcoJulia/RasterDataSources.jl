"""
    SMAP{L4} <: RasterDataSource

Data from SMAP datasets, currently just L4

See: [NSIDC](https://nsidc.org/data/smap/smap-data.html
"""
struct SMAP{L} <: RasterDataSource end

struct L4{X} end

const SMAP_URI = URI(scheme="https", host="n5eil01u.ecs.nsidc.org", path="/SMAP/")

"""
    getraster(T::Type{SMAP{L4{DS}}}; date) => Vector{String}
    getraster(T::Type{SMAP{L4{DS}}}, date)

Download SMAP weather data, choosing `DS` from (:carbon, :soilmoisture, :geophysical).

SMAP datasets come in large multi-layered HDF5 files. 
It isn't possible to download specific layers separately.
"""
getraster(T::Type{<:SMAP}; date) = getraster(T, date)
getraster(T::Type{<:SMAP}, dates::AbstractArray) = getraster.(T, dates)
function getraster(T::Type{<:SMAP}, dates::NTuple{2})
    getraster(T, _date_sequence(dates, Hour(3)))
end
function getraster(T::Type{<:SMAP}, date::Dates.TimeType)
    raster_path = rasterpath(T; date=date)
    # Manually log in and handle the redirect
    if !isfile(raster_path)
        mkpath(dirname(raster_path))
        user, password = earthdata_login()
        agent = "User-Agent" => "Wget/1.21.1"
        auth = "Authorization" => "Basic $(base64encode("$user:$password"))"

        uri = string(rasterurl(T; date=date))
        println("Starting download for $uri")
        @show user
        @show password
        @show uri

        response = HTTP.get(uri; redirect=false, verbose=2, cookies=true, status_exception=false, headers=[agent])
        redirect = response.headers[3][2]
        # @show redirect
        HTTP.download(redirect, raster_path; cookies=true, verbose=2, headers=[auth, agent])
        # response = HTTP.get(uri; 
            # redirect=false, cookies=true, verbose=2, status_exception=false,
            # headers=["User-Agent" => "Wget/1.21.1"]
        # )
        # HTTP.download(response.headers[3][2], "smap.h5";
            # cookies=true, verbose=2,
            # headers=["Authorization" => "Basic $(base64encode("$user:$passwd"))", "User-Agent" => "Wget/1.21.1"]
        # )
    end
    return raster_path
end

rasterpath(T::Type{<:SMAP}) = joinpath(rasterpath(), "SMAP")
function rasterpath(T::Type{<:SMAP{L}}; date=nothing) where L
    path = joinpath(rasterpath(SMAP), _pathsegment(L))
    return date isa Nothing ? path : joinpath(path, _date(T, date), rastername(T; date=date))
end
rastername(T::Type{<:SMAP{L}}; date) where L =
    "SMAP_L4_$(_namesegment(L))_$(_datetime(T, date))_Vv$(_namecode(date))_001.h5"
rasterurl(T::Type{<:SMAP{L}}; date) where L =
    joinpath(SMAP_URI, _pathsegment(L), _date(T, date), rastername(T; date))

_pathsegment(::Type{L4{:carbon}}) = "SPL4CMDL.005"
_pathsegment(::Type{L4{:soilmoisture}}) = "SPL4SMAU.005"
_pathsegment(::Type{L4{:geophysical}}) = "SPL4SMGP.005"

_namesegment(::Type{L4{:carbon}}) = "C_mdl"
_namesegment(::Type{L4{:soilmoisture}}) = "SM_aup"
_namesegment(::Type{L4{:geophysical}}) = "SM_gph"

function _namecode(date) 
    if date < DateTime(2016, 10)
        "5030"
    elseif date < DateTime(2018, 10)
        "5030"
    else
        "5030"
    end
end

# Utility methods

const SMAP_DAY_DATEFORMAT = DateFormat("yyyy.mm.dd")
const SMAP_FULL_DATEFORMAT = DateFormat("yyyymmddTHHMMSS")

_date(::Type{<:SMAP}, t) = Dates.format(t, SMAP_DAY_DATEFORMAT)
_datetime(::Type{<:SMAP}, t) = Dates.format(t, SMAP_FULL_DATEFORMAT)

function earthdata_login()
    if haskey(ENV, "RASTERDATASOURCES_EARTHDATA_USER") && haskey(ENV, "RASTERDATASOURCES_EARTHDATA_PASSWORD")
        user = ENV["RASTERDATASOURCES_EARTHDATA_USER"]
        password = ENV["RASTERDATASOURCES_EARTHDATA_PASSWORD"]
    else
        error("You must set `ENV[\"RASTERDATASOURCES_EARTHDATA_USER\"]` `ENV[\"RASTERDATASOURCES_EARTHDATA_PASSWORD\"]` to your NASA Earthdata login details")
    end
    return user, password
end
