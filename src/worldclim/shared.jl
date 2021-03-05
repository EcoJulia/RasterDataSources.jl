"""
    WorldClim{Union{BioClim,Climate,Weather}} <: RasterDataSource

Data from WorldClim datasets, either `BioClim`, `Climate` or `Weather`

See: [www.worldclim.org](https://www.worldclim.org)
"""
struct WorldClim{X} <: RasterDataSource end

const WORLDCLIM_URI = URI(scheme="https", host="biogeo.ucdavis.edu", path="/data/worldclim/v2.1")

resolutions(::Type{<:WorldClim}) = ("30s", "2.5m", "5m", "10m")
defres(::Type{<:WorldClim}) = "10m"

rasterpath(::Type{WorldClim{T}}) where T = joinpath(rasterpath(), "WorldClim", string(nameof(T)))
rasterpath(T::Type{<:WorldClim}, layer; kw...) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; kw...))

_zipfile_to_read(raster_name, zf) = first(filter(f -> f.name == raster_name, zf.files))

_format(::Type{WorldClim}, ::Type{SSP126}) = "ssp126"
_format(::Type{WorldClim}, ::Type{SSP245}) = "ssp245"
_format(::Type{WorldClim}, ::Type{SSP370}) = "ssp370"
_format(::Type{WorldClim}, ::Type{SSP585}) = "ssp585"

_format(::Type{WorldClim}, ::Type{BCCCSM2MR}) = "BCC-CSM2-MR"
_format(::Type{WorldClim}, ::Type{CNRMCM61}) = "CNRM-CM6-1"
_format(::Type{WorldClim}, ::Type{CNRMESM21}) = "CNRM-ESM2-1"
_format(::Type{WorldClim}, ::Type{CanESM5}) = "CanESM5"
_format(::Type{WorldClim}, ::Type{GFDLESM4}) = "GFDL-ESM4"
_format(::Type{WorldClim}, ::Type{IPSLCM6ALR}) = "IPSL-CM6A-LR"
_format(::Type{WorldClim}, ::Type{MIROCES2L}) = "MIROC-ES2L"
_format(::Type{WorldClim}, ::Type{MIROC6}) = "MIROC6"
_format(::Type{WorldClim}, ::Type{MRIESM2}) = "MRI-ESM2-0"

function _format(::Type{WorldClim}, date::Year)
    if date == Year(2030)
        return "2021-2040"
    elseif date == Year(2050)
        return "2041-2060"
    elseif date == Year(2070)
        return "2061-2080"
    elseif date == year(2090)
        return "2081-2100"
    end
    @warn "Wrong date for future worldclim, returning 2030"
    return "2021-2040"
end