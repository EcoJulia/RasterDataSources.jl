#http://biogeo.ucdavis.edu/data/worldclim/v2.1/fut/10m/wc2.1_10m_bioc_BCC-CSM2-MR_ssp126_2021-2040.zip
#http://biogeo.ucdavis.edu/data/worldclim/v2.1/fut/10m/wc2.1_10m_tmin_BCC-CSM2-MR_ssp126_2021-2040.zip

"""
    getraster(T::Type{WorldClim{BioClim}}, [layer::Integer]; res::String="10m") => String
    getraster(T::Type{WorldClim{BioClim}}, layer::Integer, res::String)

Download WorldClim weather data, choosing `layer` from `$(layers(WorldClim{BioClim}))`,
and `res` from `$(resolutions(WorldClim{BioClim}))`.

Without a layer argument, all layers will be downloaded, and a tuple of paths is returned. 
If the data is already downloaded the path will be returned.
"""
function getraster(T::Type{WorldClim{BioClim}}, ::Type{F}, layer::Integer, date=Year(2050); res::String=defres(T)) where {F <: FutureClimate}
    getraster(T, F, layer, date, res)
end
function getraster(T::Type{WorldClim{BioClim}}, ::Type{F}, layer::Integer, date, res::String) where {F <: FutureClimate}
    @assert date in Year.([2030, 2050, 2070, 2090])

    _check_layer(T, layer)
    _check_res(T, res)

    @assert res != "30s" # No 30s future data in WorldClim
    # TODO the line above might become an additional method?

    raster_path = rasterpath(T, F, date, layer; res)
    zip_path = zippath(T, F, date, layer; res)

    if !isfile(raster_path)
        _maybe_download(zipurl(T, F, date, layer; res), zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, F, date, layer; res)
        zf = ZipFile.Reader(zip_path)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

rasterpath(T::Type{<:WorldClim{BioClim}}, ::Type{F}) where {F <: FutureClimate} = joinpath(rasterpath(T), "Future", _format(WorldClim, _scenario(F)), _format(WorldClim, _model(F)))

function rasterpath(T::Type{<:WorldClim{BioClim}}, ::Type{F}, date, layer; kw...) where {F <: FutureClimate}
    return joinpath(rasterpath(T, F), rastername(T, F, date, layer; kw...))
end

function rastername(T::Type{<:WorldClim{BioClim}}, ::Type{F}, date, layer; res) where {F <: FutureClimate}
    "wc2.1_$(res)_bioc_$(_format(WorldClim, _model(F)))_$(_format(WorldClim, _scenario(F)))_.tif"
end

function zipname(T::Type{<:WorldClim{BioClim}}, ::Type{F}, date, layer; res) where {F <: FutureClimate}
    return "wc2.1_$(res)_bioc_$(_format(WorldClim, _model(F)))_$(_format(WorldClim, _scenario(F)))_$(_yearspan(WorldClim, date)).zip"
end

function zipurl(T::Type{<:WorldClim{BioClim}}, ::Type{F}, date, layer; res) where {F <: FutureClimate}
    return joinpath(WORLDCLIM_URI, "fut/$(res)", zipname(T, F, date, layer; res))
end

function zippath(T::Type{<:WorldClim{BioClim}}, ::Type{F}, date, layer; res) where {F <: FutureClimate}
    return joinpath(rasterpath(T), "zips", zipname(T, F, date, layer; res))
end
