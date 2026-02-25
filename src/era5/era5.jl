
const ARCO_ERA5_URL = "https://storage.googleapis.com/gcp-public-data-arco-era5/ar/full_37-1h-0p25deg-chunk-1.zarr-v3"

struct ERA5 <: RasterDataSource end

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

layers(::Type{ERA5}) = keys(ERA5_LAYERS)

"""
    layername(::Type{ERA5}, layer::Symbol) -> String

Convert a short layer name (e.g. `:t2m`) to the ARCO-ERA5 variable name (e.g. `"2m_temperature"`).
"""
layername(::Type{ERA5}, layer::Symbol) = ERA5_LAYERS[layer]

@doc """
    ERA5 <: RasterDataSource

Data from the ERA5 reanalysis dataset, accessed via Google's ARCO-ERA5 cloud-optimized Zarr store.

See: [ARCO-ERA5](https://cloud.google.com/storage/docs/public-datasets/era5)

The dataset contains hourly data at 0.25° resolution from 1940 to present (~3 month lag).
Data is accessed lazily - only the chunks you read are downloaded and cached locally.

## Available layers

`$(keys(ERA5_LAYERS))`

Common layers:
- `:t2m` - 2m temperature
- `:d2m` - 2m dewpoint temperature
- `:u10`, `:v10` - 10m wind components
- `:sp` - Surface pressure
- `:msl` - Mean sea level pressure
- `:tp` - Total precipitation
- `:ssrd` - Surface solar radiation downwards
- `:tcc` - Total cloud cover

## Usage

```julia
using RasterDataSources, Zarr

# Get cloud source reference
source = getraster(ERA5)

# Create caching store and open
store = Zarr.CachingHTTPStore(source)
ds = zopen(Zarr.ConsolidatedStore(store, ""))

# Access a variable (chunks download on demand and are cached)
temp = ds["2m_temperature"]

# Or use the layer symbol helper
varname = layername(ERA5, :t2m)  # "2m_temperature"
temp = ds[varname]
```

The local cache is stored at `RasterDataSources.rasterpath(ERA5)`.
Subsequent runs reuse cached chunks without re-downloading.
""" ERA5

# Path for local cache
rasterpath(::Type{ERA5}) = joinpath(rasterpath(), "ERA5", "arco-era5-zarr")

"""
    getraster(::Type{ERA5}) -> CachedCloudSource

Returns a `CachedCloudSource` for ARCO-ERA5 with the remote URL and local cache path.

Use with Zarr.jl:
```julia
source = getraster(ERA5)
store = Zarr.CachingHTTPStore(source)
ds = zopen(Zarr.ConsolidatedStore(store, ""))
```

The cache directory is `RasterDataSources.rasterpath(ERA5)`.
"""
function getraster(::Type{ERA5})
    cache_path = rasterpath(ERA5)
    mkpath(cache_path)
    CachedCloudSource(ARCO_ERA5_URL, cache_path)
end
