
const ARCO_ERA5_URL = "https://storage.googleapis.com/gcp-public-data-arco-era5/ar/full_37-1h-0p25deg-chunk-1.zarr-v3"


# Map layer symbols (short names) to ARCO-ERA5 variable names (long names)
const ERA5_LAYERS = (
    # Surface variables
    t2m = "2m_temperature",
    d2m = "2m_dewpoint_temperature",
    u10 = "10m_u_component_of_wind",
    v10 = "10m_v_component_of_wind",
    u100 = "100m_u_component_of_wind",
    v100 = "100m_v_component_of_wind",
    sp = "surface_pressure",
    msl = "mean_sea_level_pressure",
    skt = "skin_temperature",
    sst = "sea_surface_temperature",
    sd = "snow_depth",
    swvl1 = "volumetric_soil_water_layer_1",
    swvl2 = "volumetric_soil_water_layer_2",
    swvl3 = "volumetric_soil_water_layer_3",
    swvl4 = "volumetric_soil_water_layer_4",
    stl1 = "soil_temperature_level_1",
    stl2 = "soil_temperature_level_2",
    stl3 = "soil_temperature_level_3",
    stl4 = "soil_temperature_level_4",
    tcc = "total_cloud_cover",
    lcc = "low_cloud_cover",
    mcc = "medium_cloud_cover",
    hcc = "high_cloud_cover",
    cape = "convective_available_potential_energy",
    blh = "boundary_layer_height",
    tcwv = "total_column_water_vapour",
    tco3 = "total_column_ozone",
    tp = "total_precipitation",
    ssrd = "surface_solar_radiation_downwards",
    ssr = "surface_net_solar_radiation",
    str = "surface_net_thermal_radiation",
    strd = "surface_thermal_radiation_downwards",
    slhf = "surface_latent_heat_flux",
    sshf = "surface_sensible_heat_flux",
    e = "evaporation",
    ro = "runoff",
    lsm = "land_sea_mask",
)

# GoogleARCO only has SingleLevels, so ERA5{GoogleARCO,Land} has no methods.
const GoogleARCOERA5 = Union{Type{ERA5{GoogleARCO}},Type{ERA5{GoogleARCO,SingleLevels}}}

layers(::GoogleARCOERA5) = keys(ERA5_LAYERS)

"""
    layername(::Type{ERA5{GoogleARCO}}, layer::Symbol) -> String

Convert a short layer name (e.g. `:t2m`) to the ARCO-ERA5 variable name (e.g. `"2m_temperature"`).
"""
layername(::GoogleARCOERA5, layer::Symbol) = ERA5_LAYERS[layer]

@doc """
    GoogleARCO <: ERA5Source

[`ERA5`](@ref) from Google's public ARCO-ERA5 cloud-optimized Zarr store --
no account needed. `SingleLevels` only: hourly, 0.25°, 1940-present (~3 month lag). Access is
lazy: only the chunks you read are downloaded and cached locally.

See: [ARCO-ERA5](https://cloud.google.com/storage/docs/public-datasets/era5)

# Available layers
`$(keys(ERA5_LAYERS))`

# Usage
```julia
using RasterDataSources, Zarr
source = getraster(ERA5{GoogleARCO})
store = Zarr.CachingStore(source.url, source.cache)
ds = zopen(Zarr.ConsolidatedStore(store, ""))
temp = ds[layername(ERA5{GoogleARCO}, :t2m)]  # "2m_temperature"
```
""" GoogleARCO

rasterpath(::GoogleARCOERA5) = joinpath(rasterpath(), "ERA5", "arco-era5-zarr")

"""
    getraster(::Type{ERA5{GoogleARCO}}) -> CachedCloudSource

The URL of the ARCO-ERA5 Zarr store and its local cache folder.
"""
getraster(T::GoogleARCOERA5) = CachedCloudSource(ARCO_ERA5_URL, mkpath(rasterpath(T)))
