# ERA5 and ERA5-Land from three hosts, as one parametric type: `ERA5{Product,Source}`.

"""
    ERA5Product <: RasterDataSet

ERA5 product, the first parameter of [`ERA5`](@ref): [`SingleLevels`](@ref) or [`Land`](@ref).
"""
abstract type ERA5Product <: RasterDataSet end

"ERA5 single-level (surface) reanalysis: hourly, 0.25° (~31 km), 1940-present."
struct SingleLevels <: ERA5Product end

"ERA5-Land, the land-only companion to ERA5: hourly, 0.1° (~9 km), 1950-present."
struct Land <: ERA5Product end

"""
    ERA5Source

Where [`ERA5`](@ref) data comes from, its second parameter: [`GoogleARCO`](@ref),
[`CDS`](@ref) or [`ECMWF`](@ref). Each serves the same reanalysis.
"""
abstract type ERA5Source end
struct GoogleARCO <: ERA5Source end
struct CDS <: ERA5Source end
struct ECMWF <: ERA5Source end

"""
    ERA5{Product<:ERA5Product,Source<:ERA5Source} <: RasterDataSource

ERA5 reanalysis. `Product` is [`SingleLevels`](@ref) or [`Land`](@ref) (ERA5-Land);
`Source` is the host: [`GoogleARCO`](@ref) (public Zarr, no account), [`CDS`](@ref)
(Copernicus Climate Data Store API, regional NetCDF downloads) or [`ECMWF`](@ref)
(ECMWF's ARCO Zarr stores, gated by a CDS key). See each source for usage.

Omitted parameters default to `SingleLevels` and `GoogleARCO`, so `ERA5` is
`ERA5{SingleLevels,GoogleARCO}`. ERA5-Land is not on `GoogleARCO`: use
`ERA5{Land,CDS}` or `ERA5{Land,ECMWF}`.

# Example
```julia
getraster(ERA5{Land,CDS}, "2m_temperature"; date=Date(2020, 7), extent=Extent(X=(143.0, 149.0), Y=(-44.0, -40.0)))
```
"""
struct ERA5{P<:ERA5Product,S<:ERA5Source} <: RasterDataSource end

product(::Type{<:ERA5{P}}) where {P} = P
source(::Type{<:ERA5{<:Any,S}}) where {S} = S

const _ERA5_FUNCTIONS = (:getraster, :layers, :layername, :rasterpath, :rastername,
    :getraster_keywords, :date_range, :date_step)

# Omitted trailing parameters take their defaults.
_era5(::Type{ERA5}) = ERA5{SingleLevels,GoogleARCO}
_era5(::Type{ERA5{P}}) where {P} = ERA5{P,GoogleARCO}
for f in _ERA5_FUNCTIONS
    @eval $f(T::Union{Type{ERA5},Type{ERA5{P}} where P}, args...; kw...) = $f(_era5(T), args...; kw...)
    @eval $f(::Type{ERA5{Land,GoogleARCO}}, args...; kw...) = throw(ArgumentError(
        "ERA5-Land is not on GoogleARCO: use ERA5{Land,CDS} or ERA5{Land,ECMWF}"))
end

const CDS_API_URL = "https://cds.climate.copernicus.eu/api"

function _read_cdsapirc()
    url = key = nothing
    rcfile = joinpath(homedir(), ".cdsapirc")
    if isfile(rcfile)
        for line in eachline(rcfile)
            m = match(r"^\s*(url|key)\s*:\s*(.+?)\s*$", line)
            m === nothing && continue
            m[1] == "url" ? (url = something(url, m[2])) : (key = something(key, m[2]))
        end
    end
    (; url, key)
end

"""
    _cds_credentials()

Read CDS API credentials, `ENV["CDSAPI_URL"]`/`ENV["CDSAPI_KEY"]` taking
precedence over a `~/.cdsapirc` file (the format used by the Python
`cdsapi`/`ecmwfr` clients):
```
url: https://cds.climate.copernicus.eu/api
key: <PERSONAL-ACCESS-TOKEN>
```
"""
function _cds_credentials()
    file = _read_cdsapirc()
    url = get(ENV, "CDSAPI_URL", something(file.url, CDS_API_URL))
    key = get(ENV, "CDSAPI_KEY", file.key)
    isnothing(key) && throw(ArgumentError(
        "No CDS API key found. Set `ENV[\"CDSAPI_KEY\"]`, or create `~/.cdsapirc` " *
        "with a `key: <token>` line. Get a personal access token by registering at " *
        "https://cds.climate.copernicus.eu, and accept each dataset's Terms of Use " *
        "on its page there before requesting it (a one-time manual step CDS requires)."
    ))
    (url = rstrip(url, '/'), key = key)
end
