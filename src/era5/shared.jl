"""
    ERA5Product <: RasterDataSet

ERA5 product, the second parameter of [`ERA5`](@ref): [`SingleLevels`](@ref) (default) or [`Land`](@ref).
"""
abstract type ERA5Product <: RasterDataSet end

"ERA5 single-level (surface) reanalysis: hourly, 0.25° (~31 km), 1940-present."
struct SingleLevels <: ERA5Product end

"ERA5-Land, the land-only companion to ERA5: hourly, 0.1° (~9 km), 1950-present."
struct Land <: ERA5Product end

"""
    ERA5Source

Where [`ERA5`](@ref) data comes from, its first parameter: [`GoogleARCO`](@ref),
[`CDS`](@ref) or [`ECMWF`](@ref). Each serves the same reanalysis.
"""
abstract type ERA5Source end
struct GoogleARCO <: ERA5Source end
struct CDS <: ERA5Source end
struct ECMWF <: ERA5Source end

"""
    ERA5{Source<:ERA5Source,Product<:ERA5Product} <: RasterDataSource

ERA5 reanalysis. `Source` is the host: [`GoogleARCO`](@ref) (public Zarr, no account),
[`CDS`](@ref) (Copernicus Climate Data Store API, regional NetCDF downloads) or
[`ECMWF`](@ref) (ECMWF's ARCO Zarr stores, gated by a CDS key). `Product` is
[`SingleLevels`](@ref) (the default) or [`Land`](@ref) (ERA5-Land, not on `GoogleARCO`).
See each source for usage.

# Example
```julia
getraster(ERA5{CDS,Land}, :t2m; date=Date(2020, 7), extent=Extent(X=(143.0, 149.0), Y=(-44.0, -40.0)))
```
"""
struct ERA5{S<:ERA5Source,P<:ERA5Product} <: RasterDataSource end
