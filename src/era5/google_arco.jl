const GOOGLE_ARCO_ERA5_URL = "https://storage.googleapis.com/gcp-public-data-arco-era5/ar/full_37-1h-0p25deg-chunk-1.zarr-v3"

# Google has no ERA5-Land, so ERA5{Google,ARCO,Land} has no methods.
const GoogleARCOERA5 = Union{Type{ERA5},Type{ERA5{Google,ARCO}}}

layers(::GoogleARCOERA5) = keys(ERA5_LAYERS)

"""
    layername(::Type{ERA5{Google,ARCO}}, layer::Symbol) -> String

The variable name in Google's store, e.g. `"2m_temperature"` for `:temperature_2m`.
"""
layername(::GoogleARCOERA5, layer::Symbol) = get(ERA5_GOOGLE_NAMES, layer, string(layer))

rasterpath(::GoogleARCOERA5) = joinpath(rasterpath(), "ERA5", "Google", "ARCO")

"""
    getraster(::Type{ERA5{Google,ARCO}}) -> CachedCloudSource

The URL of the ARCO-ERA5 Zarr store and its local cache folder.
"""
getraster(T::GoogleARCOERA5) = CachedCloudSource(GOOGLE_ARCO_ERA5_URL, mkpath(rasterpath(T)))
