"""
    ERA5Provider

Who serves [`ERA5`](@ref) data, its first parameter: [`Google`](@ref) or [`ECMWF`](@ref).
"""
abstract type ERA5Provider end

"Google Cloud's public datasets, which host ERA5 as [`ARCO`](@ref) Zarr."
struct Google <: ERA5Provider end

"""
ECMWF, which produces ERA5 and serves it as [`ARCO`](@ref) Zarr and through the [`CDS`](@ref) API.
Both need a CDS API token in `ENV["RASTERDATASOURCES_ERA5_CDS_TOKEN"]`.
"""
struct ECMWF <: ERA5Provider end

"""
    ERA5Store

How [`ERA5`](@ref) data is served, its second parameter: [`ARCO`](@ref) or [`CDS`](@ref).
"""
abstract type ERA5Store end
struct ARCO <: ERA5Store end
struct CDS <: ERA5Store end

"""
    ERA5Product <: RasterDataSet

Optional third parameter of [`ERA5`](@ref). Omit it for ERA5 itself, or use [`Land`](@ref).
"""
abstract type ERA5Product <: RasterDataSet end

"ERA5-Land, a rerun of ERA5's land model at 0.1° (~9 km): hourly, 1950-present."
struct Land <: ERA5Product end

"""
    ERA5{Provider<:ERA5Provider,Store<:ERA5Store,Product<:ERA5Product} <: RasterDataSource

ERA5 reanalysis: hourly, 0.25° (~31 km), 1940-present. Available as:

- `ERA5` or `ERA5{Google,ARCO}`: Google's public Zarr store, no account needed.
- `ERA5{ECMWF,ARCO}` and `ERA5{ECMWF,ARCO,Land}`: ECMWF's Zarr stores.
- `ERA5{ECMWF,CDS}` and `ERA5{ECMWF,CDS,Land}`: NetCDF downloads from the Climate Data Store API.

Layers use the CDS variable names, so they work with every provider, except:
- Heights go last, e.g. `:temperature_2m` is CDS `2m_temperature`.
- `:geopotential_at_surface` is CDS `geopotential`.
- `:snow_depth_water_equivalent` is ERA5's CDS `snow_depth`. Google also calls it `snow_depth`,
    and ERA5-Land calls it `snow_depth_water_equivalent`, all in metres of water equivalent. ERA5-Land has both, and
    its `:snow_depth` is in metres of snow.

See [`ARCO`](@ref) and [`CDS`](@ref) for usage.

# Layers

✓ where the source uses the layer name, otherwise the name it uses. The short name is the
variable name in ECMWF files.

$(_era5_layer_table())
"""
struct ERA5{P<:ERA5Provider,S<:ERA5Store,D<:ERA5Product} <: RasterDataSource end

_era5_layers(::Type{<:ERA5}) = ERA5_LAYERS
_era5_layers(::Type{<:ERA5{<:ERA5Provider,<:ERA5Store,Land}}) = ERA5_LAND_LAYERS

# ECMWF files use the short names.
layername(T::Type{<:ERA5{ECMWF}}, layer::Symbol) = _era5_layers(T)[layer]
