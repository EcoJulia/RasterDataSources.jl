layers(::Type{WorldClim{Weather}}) = (:tmin, :tmax, :prec)

"""
    getraster(T::Type{WorldClim{Weather}}, [layer::Union{Tuple,Symbol}]; date) => Union{String,Tuple{String},Vector{String}}
    getraster(T::Type{WorldClim{Weather}}, layer::Symbol, date)

Download [`WorldClim`](@ref) [`Weather`](@ref) data, for `layer`/s in: `$(layers(WorldClim{Weather}))`.
Without a layer argument, all layers will be downloaded, and a tuple of paths returned. 

# Keywords
- `date`: a `DateTime` or iterable of `DateTime`. For multiple dates, multiple 
    filenames will be returned. WorldClim Weather is available with a daily timestep. 

Returns the filepath/s of the downloaded or pre-existing files.
"""
getraster(T::Type{WorldClim{Weather}}, layers; date) = _getraster(T, layers, date)

function _getraster(T::Type{WorldClim{Weather}}, layers, date::Tuple)
    _getraster(T, layers, _date_sequence(date, Month(1)))
end
function _getraster(T::Type{WorldClim{Weather}}, layers, dates::AbstractArray)
    @show layers
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{WorldClim{Weather}}, layers::Tuple, date::Dates.TimeType)
    _map_layers(T, layers, date)
end
function _getraster(T::Type{WorldClim{Weather}}, layer::Symbol, date::Dates.TimeType)
    decadestart = Date.(1960:10:2020)
    for i in eachindex(decadestart[1:end-1])
        # At least one date is in the decade
        date >= decadestart[i] && date < decadestart[i+1] || continue
        zip_path = zippath(T, layer; decade=decadestart[i])
        _maybe_download(zipurl(T, layer; decade=decadestart[i]), zip_path)
        zf = ZipFile.Reader(zip_path)
        raster_path = rasterpath(T, layer; date=date)
        mkpath(dirname(raster_path))
        if !isfile(raster_path)
            raster_name = rastername(T, layer; date=date)
            println("Writing $(raster_path)...")
            write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        end
        close(zf)
        return raster_path
    end
    error("Date $date not between 1960 and 2020")
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
