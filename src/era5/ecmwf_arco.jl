const ECMWF_ARCO_HOST = "arco.datastores.ecmwf.int"

@doc """
    ARCO <: ERA5Store

Analysis-Ready, Cloud-Optimised Zarr stores, read remotely chunk by chunk rather than
downloaded. `getraster` returns a [`CachedCloudSource`](@ref) to open with Zarr.jl,
and `layername(T, layer)` gives the variable name in the store.

# Google

`ERA5` or `ERA5{Google,ARCO}`: Google's public ARCO-ERA5 store, no account needed.
ERA5 only, ~3 month lag. See [ARCO-ERA5](https://cloud.google.com/storage/docs/public-datasets/era5).
All layers are in one store.

    getraster(ERA5{Google,ARCO})

```julia
using RasterDataSources, Zarr
source = getraster(ERA5)
store = Zarr.CachingStore(source.url, source.cache)
ds = zopen(Zarr.ConsolidatedStore(store, ""))
temp = ds[layername(ERA5, :total_precipitation)]
```

# ECMWF

`ERA5{ECMWF,ARCO}` and `ERA5{ECMWF,ARCO,Land}`: ECMWF's stores, with no job queue
(unlike [`CDS`](@ref)). Not guaranteed byte-identical to a CDS download. The CDS API
token is sent as a `Bearer` header by the caller. Each store holds several layers,
and only some ERA5 layers are available.

!!! warning
    ECMWF describes ARCO access as a **beta service**. Licence: CC-BY.

    getraster(T::Type{<:ERA5{ECMWF,ARCO}}, [layer]; chunking=:geo)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `layers(T)`, listed in [`ERA5`](@ref).

# Keywords
- `chunking`: `:geo` (default, small area/long time) or `:time` (large
    area/short time).

```julia
using RasterDataSources, Zarr
T = ERA5{ECMWF,ARCO,Land}
source = getraster(T, :total_precipitation)
remote = Zarr.HTTPStore(source.url; headers=["Authorization" => "Bearer \$key"])
ds = zopen(Zarr.CachingStore(remote, DirectoryStore(source.cache)))
tp = ds[layername(T, :total_precipitation)]
```
""" ARCO

_ecmwf_arco_groups(::Type{<:ERA5{ECMWF,ARCO}}) = ECMWF_ERA5_GROUPS
_ecmwf_arco_groups(::Type{<:ERA5{ECMWF,ARCO,Land}}) = ECMWF_ERA5_LAND_GROUPS
_ecmwf_arco_dataset_path(::Type{<:ERA5{ECMWF,ARCO}}) = "reanalysis_era5_single_levels"
_ecmwf_arco_dataset_path(::Type{<:ERA5{ECMWF,ARCO,Land}}) = "reanalysis_era5_land"

_ecmwf_arco_group(T::Type{<:ERA5{ECMWF,ARCO}}, layer::Symbol) =
    only(g for g in _ecmwf_arco_groups(T) if layer in g.layers)

layers(T::Type{<:ERA5{ECMWF,ARCO}}) = _group_layers(_ecmwf_arco_groups(T))
getraster_keywords(::Type{<:ERA5{ECMWF,ARCO}}) = (:chunking,)

_check_arco_chunking(chunking::Symbol) =
    chunking in (:geo, :time) || throw(ArgumentError("chunking must be :geo or :time, got $chunking"))

function _ecmwf_arco_group_url(T::Type{<:ERA5{ECMWF,ARCO}}, layer::Symbol; chunking::Symbol=:geo)
    group = _ecmwf_arco_group(T, layer)
    URI(scheme="https", host=ECMWF_ARCO_HOST,
        path="/cadl-arco-$chunking-$(lpad(group.bucket, 3, '0'))/arco/$(_ecmwf_arco_dataset_path(T))/$(group.path)/$(chunking)Chunked.zarr")
end

rasterpath(::Type{<:ERA5{ECMWF,ARCO}}) = joinpath(rasterpath(), "ERA5", "ECMWF", "ARCO")
rasterpath(::Type{<:ERA5{ECMWF,ARCO,Land}}) = joinpath(rasterpath(), "ERA5", "ECMWF", "ARCO", "Land")
rasterpath(T::Type{<:ERA5{ECMWF,ARCO}}, layer::Symbol; chunking::Symbol=:geo) =
    joinpath(rasterpath(T), _ecmwf_arco_group(T, layer).path, string(chunking))

getraster(T::Type{<:ERA5{ECMWF,ARCO}}, layers::Union{Tuple,Symbol}; chunking::Symbol=:geo) =
    (_check_arco_chunking(chunking); _getraster(T, layers, chunking))
_getraster(T::Type{<:ERA5{ECMWF,ARCO}}, layers::Tuple, chunking) = _map_layers(T, layers, chunking)
function _getraster(T::Type{<:ERA5{ECMWF,ARCO}}, layer::Symbol, chunking)
    _check_layer(T, layer)
    CachedCloudSource(string(_ecmwf_arco_group_url(T, layer; chunking)), mkpath(rasterpath(T, layer; chunking)))
end
