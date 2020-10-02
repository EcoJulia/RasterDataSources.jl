
const WORLDCLIM_URL = "https://biogeo.ucdavis.edu/data/worldclim/v2.1"

rasterpath(::Type{WorldClim{T}}) where T = 
    joinpath(rasterpath(), "WorldClim", string(nameof(T)))
rasterpath(T::Type{<:WorldClim}, layer) = joinpath(rasterpath(T), string(layer))
rasterpath(T::Type{<:WorldClim}, layer, x) =
    joinpath(rasterpath(T, layer), rastername(T, layer, x))

_zipfile_to_read(raster_name, zf) = first(filter(f -> f.name == raster_name, zf.files))
