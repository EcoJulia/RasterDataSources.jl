struct WorldClim{X} <: RasterDataSource end

const WORLDCLIM_URI = URI(scheme="https", host="biogeo.ucdavis.edu", path="/data/worldclim/v2.1")

resolutions(::Type{<:WorldClim}) = ("30s", "2.5m", "5m", "10m")

rasterpath(::Type{WorldClim{T}}) where T = 
    joinpath(rasterpath(), "WorldClim", string(nameof(T)))
rasterpath(T::Type{<:WorldClim}, layer) = joinpath(rasterpath(T), string(layer))
rasterpath(T::Type{<:WorldClim}, layer, x) =
    joinpath(rasterpath(T, layer), rastername(T, layer, x))

_zipfile_to_read(raster_name, zf) = first(filter(f -> f.name == raster_name, zf.files))
