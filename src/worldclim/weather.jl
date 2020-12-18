layers(::Type{WorldClim{Weather}}) = (:tmin, :tmax, :prec)

"""
    getraster(T::Type{WorldClim{Weather}}, [layer::Symbol]; date) => Vector{String}

Download WorldClim weather data, choosing layers from: $(layers(WorldClim{Weather})).

Without a layer argument, all layers will be getrastered, and a tuple of paths is returned. 
If the data is already getrastered the path will be returned.
"""
function getraster(T::Type{WorldClim{Weather}}, layer::Symbol; date)
    date = _date_sequence(date, Month(1))
    decadestart = Date.(1960:10:2020)
    raster_paths = String[]

    for i in eachindex(decadestart[1:end-1])
        # At least one date is in the decade
        any(d -> d >= decadestart[i] && d < decadestart[i+1], date) || continue
        zip_path = zippath(T, layer, decadestart[i])
        _maybe_download(zipurl(T, layer, decadestart[i]), zip_path)
        zf = ZipFile.Reader(zip_path)
        for d in date
            raster_path = rasterpath(T, layer; date=d)
            mkpath(dirname(raster_path))
            if !isfile(raster_path)
                raster_name = rastername(T, layer, d)
                println("Writing $(raster_path)...")
                write(raster_path, read(_zipfile_to_read(raster_name, zf)))
            end
            push!(raster_paths, raster_path)
        end
        close(zf)
    end
    return raster_paths
end

const WEATHER_DECADES = Dict(Date(1960) => "1960-1969",
                             Date(1970) => "1970-1979",
                             Date(1980) => "1980-1989",
                             Date(1990) => "1990-1999",
                             Date(2000) => "2000-2009",
                             Date(2010) => "2010-2018")

rastername(T::Type{<:WorldClim{Weather}}, layer; date) =
    joinpath("wc2.1_2.5m_$(layer)_$(_date2string(T, date)).tif")
zipname(T::Type{<:WorldClim{Weather}}, layer; decade) =
    "wc2.1_2.5m_$(layer)_$(WEATHER_DECADES[decade]).zip"
zipurl(T::Type{<:WorldClim{Weather}}, layer; decade) =
    joinpath(WORLDCLIM_URI, "hist", zipname(T, layer; decade))
zippath(T::Type{<:WorldClim{Weather}}, layer; decade) =
    joinpath(rasterpath(T), "zips", zipname(T, layer; decade))

# Utility methods

_dateformat(::Type{<:WorldClim}) = DateFormat("yyyy-mm")

_filename2date(T::Type{<:WorldClim}, fn::AbstractString) =
    _string2date(T, basename(fn)[findfirst(r"\d\d\d\d-\d\d", basename(fn))])
