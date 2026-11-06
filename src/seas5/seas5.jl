# Layers use the CDS variable names with heights last, like `ERA5`. Short names are from CDS NetCDF files.
const SEAS5_LAYERS = (
    u_component_of_wind_10m = "u10",
    v_component_of_wind_10m = "v10",
    wind_gust_since_previous_post_processing_10m = "fg10",
    dewpoint_temperature_2m = "d2m",
    temperature_2m = "t2m",
    eastward_turbulent_surface_stress = "ewss",
    evaporation = "e",
    maximum_2m_temperature_in_the_last_24_hours = "mx2t24",
    mean_sea_level_pressure = "msl",
    minimum_2m_temperature_in_the_last_24_hours = "mn2t24",
    northward_turbulent_surface_stress = "nsss",
    runoff = "ro",
    sea_ice_cover = "siconc",
    sea_surface_temperature = "sst",
    snow_density = "rsn",
    snow_depth_water_equivalent = "sd",
    snowfall = "sf",
    soil_temperature_level_1 = "stl1",
    sub_surface_runoff = "ssro",
    surface_latent_heat_flux = "slhf",
    surface_net_solar_radiation = "ssr",
    surface_net_thermal_radiation = "str",
    surface_runoff = "sro",
    surface_sensible_heat_flux = "sshf",
    surface_solar_radiation_downwards = "ssrd",
    surface_thermal_radiation_downwards = "strd",
    toa_incident_solar_radiation = "tisr",
    top_net_solar_radiation = "tsr",
    top_net_thermal_radiation = "ttr",
    total_cloud_cover = "tcc",
    total_column_cloud_ice_water = "tciw",
    total_column_cloud_liquid_water = "tclw",
    total_column_water_vapour = "tcwv",
    total_precipitation = "tp",
    volumetric_soil_moisture = "vsw",
)
# Monthly files hold time means, so many short names differ, e.g. `total_precipitation` is the rate `tprate`.
const SEAS5_MONTHLY_LAYERS = (
    u_component_of_wind_10m = "u10",
    v_component_of_wind_10m = "v10",
    wind_gust_since_previous_post_processing_10m = "fg10",
    wind_speed_10m = "si10",
    dewpoint_temperature_2m = "d2m",
    temperature_2m = "t2m",
    east_west_surface_stress_rate_of_accumulation = "ewssra",
    evaporation = "erate",
    maximum_2m_temperature_in_the_last_24_hours = "mx2t24",
    mean_sea_level_pressure = "msl",
    mean_sub_surface_runoff_rate = "mssror",
    mean_surface_runoff_rate = "msror",
    minimum_2m_temperature_in_the_last_24_hours = "mn2t24",
    north_south_surface_stress_rate_of_accumulation = "nsssra",
    runoff = "mrort",
    sea_ice_cover = "siconc",
    sea_surface_temperature = "sst",
    snow_density = "rsn",
    snow_depth_water_equivalent = "sd",
    snowfall = "mtsfr",
    soil_temperature_level_1 = "stl1",
    solar_insolation_rate_of_accumulation = "soira",
    surface_latent_heat_flux = "mslhfl",
    surface_sensible_heat_flux = "msshfl",
    surface_solar_radiation = "msnsrf",
    surface_solar_radiation_downwards = "msdsrf",
    surface_thermal_radiation = "msntrf",
    surface_thermal_radiation_downwards = "msdtrf",
    top_solar_radiation = "mtnsrf",
    top_thermal_radiation = "mtntrf",
    total_cloud_cover = "tcc",
    total_column_cloud_ice_water = "tciw",
    total_column_cloud_liquid_water = "tclw",
    total_column_water_vapour = "tcwv",
    total_precipitation = "tprate",
)
# CDS names, where they differ from the layer names above.
const SEAS5_CDS_NAMES = (; ERA5_CDS_NAMES..., wind_speed_10m = "10m_wind_speed")
# Layers with a lead time every 6 hours. All other `SEAS5` layers have one every 24 hours.
const SEAS5_6_HOURLY_LAYERS = (
    :u_component_of_wind_10m, :v_component_of_wind_10m, :dewpoint_temperature_2m, :temperature_2m,
    :mean_sea_level_pressure, :sea_surface_temperature, :soil_temperature_level_1, :total_cloud_cover,
)
const SEAS5_SYSTEMS = ("51", "5")
const SEAS5_PRODUCT_TYPES = (
    "monthly_mean", "monthly_minimum", "monthly_maximum", "monthly_standard_deviation", "ensemble_mean", "hindcast_climate_mean",
)

function _seas5_layer_table()
    header = "| Layer | `SEAS5` | `SEAS5{Month}` |\n| :--- | :--- | :--- |"
    cell(layers, layer) = haskey(layers, layer) ? "`$(layers[layer])`" : ""
    rows = map(sort!(union(keys(SEAS5_LAYERS), keys(SEAS5_MONTHLY_LAYERS)))) do layer
        "| `:$layer` | $(cell(SEAS5_LAYERS, layer)) | $(cell(SEAS5_MONTHLY_LAYERS, layer)) |"
    end
    join([header; rows], "\n")
end

"""
    SEAS5{Period} <: RasterDataSource

ECMWF SEAS5 seasonal forecasts at 1°, from the Copernicus Climate Data Store (CDS). A forecast
starts on the 1st of each month and has an ensemble of 51 members, or 25 in the hindcasts before 2017.

- `SEAS5`: lead times every 6 or 24 hours depending on the layer, out to 215 days.
- `SEAS5{Month}`: monthly statistics for lead months 1 to 6, where `Month` is from `Dates`.

Needs your CDS API token in `ENV["RASTERDATASOURCES_ERA5_CDS_TOKEN"]`, and the licence accepted
on each dataset's page on the CDS website.

!!! warning
    CDS queues requests, and each layer and month is a separate request. `SEAS5` requests have
    taken from one minute to hours just to start. Interrupting `getraster` cancels the request.

See: [`SEAS5`](https://cds.climate.copernicus.eu/datasets/seasonal-original-single-levels),
[`SEAS5{Month}`](https://cds.climate.copernicus.eu/datasets/seasonal-monthly-single-levels)

# Usage with `getraster`
    getraster(T::Type{<:SEAS5}, [layer]; date, extent, system)
    getraster(T::Type{SEAS5{Month}}, [layer]; date, extent, system, product_type)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `layers(T)`, listed below. Each layer is a
    separate NetCDF file, holding the variable `layername(T, layer)`.

# Keywords
- `date`: the month the forecast starts, as a `Date`, `AbstractVector` of `Date`, or a `Tuple`
    of start and end dates. One file is downloaded per month.
- `extent`: an `Extents.Extent` bounding box, e.g. `Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))`.
    It is expanded outward to the grid.
- `system`: $(join(SEAS5_SYSTEMS, ", ")), "$(first(SEAS5_SYSTEMS))" by default.
- `product_type`: $(join(SEAS5_PRODUCT_TYPES, ", ")), "$(first(SEAS5_PRODUCT_TYPES))" by default.
    `SEAS5{Month}` only.

# Layers

The short name of each layer, which is the variable name in its files.

$(_seas5_layer_table())

# Example
```julia
using RasterDataSources, Extents, Dates
extent = Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))
getraster(SEAS5, (:temperature_2m, :total_precipitation); date=Date(2025, 1, 1), extent)
getraster(SEAS5{Month}, :temperature_2m; date=Date(2025, 1, 1), extent, product_type="ensemble_mean")
```
"""
struct SEAS5{P<:Dates.Period} <: RasterDataSource end

_seas5_layers(::Type{<:SEAS5}) = SEAS5_LAYERS
_seas5_layers(::Type{<:SEAS5{Month}}) = SEAS5_MONTHLY_LAYERS

layers(T::Type{<:SEAS5}) = keys(_seas5_layers(T))
layername(T::Type{<:SEAS5}, layer::Symbol) = _seas5_layers(T)[layer]

date_step(::Type{<:SEAS5}) = Month(1)
date_range(::Type{<:SEAS5}) = (Date(1981, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{<:SEAS5}) = (:date, :extent, :system)
getraster_keywords(::Type{<:SEAS5{Month}}) = (:date, :extent, :system, :product_type)

rasterpath(::Type{<:SEAS5}) = joinpath(rasterpath(), "SEAS5")
rasterpath(::Type{<:SEAS5{Month}}) = joinpath(rasterpath(), "SEAS5", "Month")

rastername(T::Type{<:SEAS5}, layer::Symbol; date, extent, kw...) = _cds_rastername(T, date, extent)
rasterpath(T::Type{<:SEAS5}, layer::Symbol; date, extent, system=first(SEAS5_SYSTEMS)) =
    joinpath(rasterpath(T), "system$system", string(layer), rastername(T, layer; date, extent))
rasterpath(T::Type{<:SEAS5{Month}}, layer::Symbol; date, extent, system=first(SEAS5_SYSTEMS), product_type=first(SEAS5_PRODUCT_TYPES)) =
    joinpath(rasterpath(T), product_type, "system$system", string(layer), rastername(T, layer; date, extent))

getraster(T::Type{<:SEAS5}, layers::Union{Tuple,Symbol}; date, extent, system=first(SEAS5_SYSTEMS)) =
    _getraster(T, layers, date, extent; system)
getraster(T::Type{<:SEAS5{Month}}, layers::Union{Tuple,Symbol}; date, extent, system=first(SEAS5_SYSTEMS), product_type=first(SEAS5_PRODUCT_TYPES)) =
    _getraster(T, layers, date, extent; system, product_type)

_getraster(T::Type{<:SEAS5}, layers, dates::Tuple{<:Any,<:Any}, extent; kw...) =
    _getraster(T, layers, date_sequence(T, dates), extent; kw...)
_getraster(T::Type{<:SEAS5}, layers, dates::AbstractArray, extent; kw...) =
    map(d -> _getraster(T, layers, d, extent; kw...), dates)
_getraster(T::Type{<:SEAS5}, layers::Tuple, date::TimeType, extent; kw...) =
    _map_layers(T, layers, date, extent; kw...)
function _getraster(T::Type{<:SEAS5}, layer::Symbol, date::TimeType, extent::Extents.Extent; kw...)
    _check_layer(T, layer)
    _check_seas5_keywords(; kw...)
    path = rasterpath(T, layer; date, extent, kw...)
    isfile(path) ? path : _cds_retrieve(T, layer, date, extent, path; kw...)
end

function _check_seas5_keywords(; system, product_type=first(SEAS5_PRODUCT_TYPES))
    system in SEAS5_SYSTEMS || throw(ArgumentError("System $system not in $SEAS5_SYSTEMS"))
    product_type in SEAS5_PRODUCT_TYPES || throw(ArgumentError("Product type $product_type not in $SEAS5_PRODUCT_TYPES"))
end

_cds_dataset_id(::Type{<:SEAS5}) = "seasonal-original-single-levels"
_cds_dataset_id(::Type{<:SEAS5{Month}}) = "seasonal-monthly-single-levels"
_cds_cells_per_degree(::Type{<:SEAS5}) = 1

_seas5_leadtimes(layer::Symbol) = layer in SEAS5_6_HOURLY_LAYERS ? (6:6:5160) : (24:24:5160)

_seas5_inputs(::Type{<:SEAS5}, layer; system) =
    Dict("day" => ["01"], "leadtime_hour" => string.(_seas5_leadtimes(layer)))
_seas5_inputs(::Type{<:SEAS5{Month}}, layer; system, product_type) =
    Dict("product_type" => [product_type], "leadtime_month" => string.(1:6))

function _cds_request_body(T::Type{<:SEAS5}, layer::Symbol, date::TimeType, extent::Extents.Extent; kw...)
    inputs = Dict{String,Any}(
        "originating_centre" => "ecmwf",
        "system" => kw[:system],
        "variable" => [get(SEAS5_CDS_NAMES, layer, string(layer))],
        "year" => [Dates.format(date, "yyyy")],
        "month" => [Dates.format(date, "mm")],
        "area" => _cds_area(_cds_snap(T, extent)),
        "data_format" => "netcdf",
    )
    merge!(inputs, _seas5_inputs(T, layer; kw...))
    Dict("inputs" => inputs)
end
