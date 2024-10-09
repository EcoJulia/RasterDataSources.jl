"""
    WorldClim{Union{BioClim,Climate,Weather}} <: RasterDataSource

Data from WorldClim datasets, either [`BioClim`](@ref), [`Climate`](@ref) or 
[`Weather`](@ref).

See: [www.worldclim.org](https://www.worldclim.org)
"""
struct WorldClim{X} <: RasterDataSource end

const WORLDCLIM_URI = URI(scheme="https", host="geodata.ucdavis.edu", path="/climate/worldclim/2_1")

resolutions(::Type{<:WorldClim}) = ("30s", "2.5m", "5m", "10m")
defres(::Type{<:WorldClim}) = "10m"

rasterpath(::Type{WorldClim}) = joinpath(rasterpath(), "WorldClim")
rasterpath(::Type{WorldClim{T}}) where T = joinpath(rasterpath(WorldClim), string(nameof(T)))
rasterpath(T::Type{<:WorldClim}, layer; kw...) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; kw...))

_zipfile_to_read(raster_name, zf) = first(filter(f -> f.name == raster_name, zf.files))
