
# NCEP/NCAR Reanalysis 1 and NCEP/DOE Reanalysis 2, organised on orthogonal axes:
#
#   group       — product family (variable set + grid):
#                   PressureLevels : pressure-level analysis, 2.5° lat/lon grid
#                   Surface : surface analysis, 2.5° lat/lon grid
#                   SurfaceFlux : surface forecast fluxes on the T62 Gaussian grid
#                                 (2 m / 10 m vars, radiation, precip)
#   reanalysis  — 1 (NCEP/NCAR, 1948–) or 2 (NCEP/DOE, 1979–)
#   period      — temporal resolution. The data is natively 6-hourly; Day and Month
#                 are aggregate products NOAA publishes for some groups. Native is the
#                 default, so it is the omittable trailing parameter.
abstract type NCEPGroup end
struct PressureLevels    <: NCEPGroup end
struct Surface     <: NCEPGroup end
struct SurfaceFlux <: NCEPGroup end

"""
    SixHour

The native NCEP cadence: four steps per day (00, 06, 12, 18 UTC). The default
`period` of [`NCEP`](@ref). A singleton rather than `Hour(6)` because 6-hourly is
the one correct native step — no other sub-daily value exists.
"""
struct SixHour end

"""
    NCEP{Group<:NCEPGroup, Reanalysis, Period} <: RasterDataSource

Data from the NCEP/NCAR Reanalysis 1 (1948–2026) and NCEP/DOE Reanalysis 2
(1979–present) datasets.

See: https://psl.noaa.gov/data/gridded/data.ncep.reanalysis.html and
  https://psl.noaa.gov/data/gridded/data.ncep.reanalysis2.html

# Type Parameters
- `Group`: `PressureLevels`, `Surface`, or `SurfaceFlux`.
- `Reanalysis`: `1` or `2`.
- `Period`: `SixHour` (native, default), `Day`, or `Month`.

`NCEP{Surface, 2}` is the native 6-hourly surface analysis from Reanalysis 2;
`NCEP{PressureLevels, 1, Day}` is the daily Reanalysis 1 pressure-level aggregate.

## Usage

```julia
getraster(NCEP{Group, Reanalysis, Period}, layer; date)
```

# Keywords
- `date`: A `Date` or `DateTime`. The year selects the file for sub-monthly data.

# Layers
| Layer Symbol | Description | Units | Group |
| :--- | :--- | :--- | :--- |
| `:tmax` | Max Temperature | K | `SurfaceFlux` |
| `:tmin` | Min Temperature | K | `SurfaceFlux` |
| `:air_2m` | Air Temperature (2m) | K | `SurfaceFlux` |
| `:shum_2m` | Specific Humidity (2m) | kg/kg | `SurfaceFlux` |
| `:prate` | Precipitation Rate | Kg/m²/s | `SurfaceFlux` |
| `:pres` | Pressure | Pa | `SurfaceFlux` |
| `:dswrf` | Downward Shortwave Flux | W/m² | `SurfaceFlux` |
| `:dlwrf` | Downward Longwave Flux | W/m² | `SurfaceFlux` |
| `:ulwrf` | Upward Longwave Flux | W/m² | `SurfaceFlux` |
| `:uwnd_10m` | U-Wind (10m) | m/s | `SurfaceFlux` |
| `:vwnd_10m` | V-Wind (10m) | m/s | `SurfaceFlux` |
| `:tcdc` | Total Cloud Cover | % | `SurfaceFlux` (2005 only) |
| `:hgt` | Geopotential Height | m | `PressureLevels` |
| `:rhum` | Relative Humidity | % | `PressureLevels` |
| `:shum` | Specific Humidity | kg/kg | `PressureLevels` |
| `:air` | Air Temperature | K | `PressureLevels` |
| `:uwnd` | U-Wind | m/s | `PressureLevels` |
| `:vwnd` | V-Wind | m/s | `PressureLevels` |
| `:omega` | Vertical Velocity | Pa/s | `PressureLevels` |
| `:pr_wtr` | Precipitable Water | kg/m² | `Surface` (6-hourly, monthly) |
| `:pres_sfc` | Surface Pressure | Pa | `Surface` (6-hourly; daily R2) |
| `:lftx` | Surface Lifted Index | K | `Surface` (6-hourly) |
| `:slp` | Sea Level Pressure | Pa | `Surface` (daily/monthly, R1) |
| `:mslp` | Mean Sea Level Pressure | Pa | `Surface` (daily, R2) |
| `:pr_wtr_eatm`| Precipitable Water | kg/m² | `Surface` (daily, R2) |

# Example
```julia
getraster(NCEP{PressureLevels, 1, Day}, :hgt; date=Date(2001))
```
"""
struct NCEP{G<:NCEPGroup, R, P} <: RasterDataSource end

group(::Type{<:NCEP{G}})        where {G<:NCEPGroup} = G
reanalysis(::Type{<:NCEP{G,R}}) where {G,R}         = R
period(::Type{<:NCEP{G,R,P}})   where {G,R,P}       = P
period(::Type{NCEP{G,R}})       where {G,R}         = SixHour   # trailing param omitted → native

# Mappings from user-friendly layer names to filename parts
const PRESSURE_MAP = (hgt = "hgt", rhum = "rhum", shum = "shum", air = "air", uwnd = "uwnd", vwnd = "vwnd", omega = "omega")
const SURFACE_MAP = (pr_wtr = "pr_wtr.eatm", pres_sfc = "pres.sfc", lftx = "lftx.sfc")
const SURFACE_DAILY_MAP = (slp = "slp",)
const SURFACE_DAILY_R2_MAP = (mslp = "mslp", pres_sfc = "pres.sfc", pr_wtr_eatm = "pr_wtr.eatm")
const SURFACE_MONTHLY_MAP = (slp = "slp", pr_wtr = "pr_wtr")
const SURFACEFLUX_MAP = (tmax = "tmax.2m.gauss", tmin = "tmin.2m.gauss", air_2m = "air.2m.gauss", shum_2m = "shum.2m.gauss", prate = "prate.sfc.gauss", pres = "pres.sfc.gauss", dswrf = "dswrf.sfc.gauss", dlwrf = "dlwrf.sfc.gauss", ulwrf = "ulwrf.sfc.gauss", uwnd_10m = "uwnd.10m.gauss", vwnd_10m = "vwnd.10m.gauss", tcdc = "tcdc.eatm.gauss")

# Layer name → filename-part map for a given (group, reanalysis, period).
# Pressure is uniform; Surface's published variables differ by period and reanalysis.
_layer_map(::Type{Pressure}, R, P) = PRESSURE_MAP
_layer_map(::Type{SurfaceFlux}, R, ::Type{SixHour}) = SURFACEFLUX_MAP
_layer_map(::Type{Surface}, R, ::Type{SixHour}) = SURFACE_MAP
_layer_map(::Type{Surface}, R, ::Type{Day}) = R == 2 ? SURFACE_DAILY_R2_MAP : SURFACE_DAILY_MAP
_layer_map(::Type{Surface}, R, ::Type{Month}) = SURFACE_MONTHLY_MAP

_layer_map(T::Type{<:NCEP}) = _layer_map(group(T), reanalysis(T), period(T))

layers(T::Type{<:NCEP}) = keys(_layer_map(T))

# Yearly files for sub-monthly data; monthly data is a single file (date irrelevant).
date_step(T::Type{<:NCEP}) = _date_step(period(T))
_date_step(::Type{Month}) = Year(100)
_date_step(::Type{<:Any}) = Year(1)

getraster(T::Type{<:NCEP}, layer::Union{Tuple,Symbol}; date) = _getraster(T, layer, date)

getraster_keywords(::Type{<:NCEP}) = (:date,)

function _getraster(T::Type{<:NCEP}, layer::Union{Tuple,Symbol}, dates::Tuple{<:Any,<:Any})
    _getraster(T, layer, date_sequence(T, dates))
end
function _getraster(T::Type{<:NCEP}, layers::Union{Tuple,Symbol}, dates::AbstractArray)
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{<:NCEP}, layers::Tuple, date::Dates.TimeType)
    _map_layers(T, layers, date)
end
function _getraster(T::Type{<:NCEP}, layer::Symbol, date::Dates.TimeType)
    _check_layer(T, layer)
    raster_path = rasterpath(T, layer; date=date)
    mkpath(dirname(raster_path))
    if !isfile(raster_path)
        url = rasterurl(T, layer; date=date)
        _maybe_download(url, raster_path)
    end
    return raster_path
end

_filename_part(T::Type{<:NCEP}, layer) = _layer_map(T)[layer]

# Server subdirectory for the (group, reanalysis, period). The Gaussian-grid flux
# directory is named differently between the two reanalyses.
_category_dir(::Type{PressureLevels}, R, ::Type{SixHour}) = ("pressure",)
_category_dir(::Type{PressureLevels}, R, ::Type{Day})     = ("Dailies", "pressure")
_category_dir(::Type{PressureLevels}, R, ::Type{Month})   = ("Monthlies", "pressure")
_category_dir(::Type{Surface}, R, ::Type{SixHour})  = ("surface",)
_category_dir(::Type{Surface}, R, ::Type{Day})      = ("Dailies", "surface")
_category_dir(::Type{Surface}, R, ::Type{Month})    = ("Monthlies", "surface")
_category_dir(::Type{SurfaceFlux}, R, ::Type{SixHour}) = (R == 2 ? "gaussian_grid" : "surface_gauss",)

_category_dir(T::Type{<:NCEP}) = _category_dir(group(T), reanalysis(T), period(T))

_dataset_dir(R) = R == 2 ? "reanalysis2" : "reanalysis"

# Monthly data lives in single `.mon.mean.nc` files; everything else is per-year.
rastername(T::Type{<:NCEP}, layer; date) = _rastername(period(T), _filename_part(T, layer); date)
_rastername(::Type{Month}, part; date) = "$part.mon.mean.nc"
_rastername(::Type, part; date) = "$part.$(year(date)).nc"

rasterpath(T::Type{<:NCEP}) = joinpath(rasterpath(), "NCEP")
function rasterpath(T::Type{<:NCEP{G,R}}, layer; date) where {G,R}
    joinpath(rasterpath(T), _dataset_dir(R), _category_dir(T)..., rastername(T, layer; date))
end

function rasterurl(T::Type{<:NCEP{G,R}}, layer; date) where {G,R}
    base_url = "https://downloads.psl.noaa.gov/Datasets/ncep.$(_dataset_dir(R))/"
    path = join(_category_dir(T), "/")
    name = rastername(T, layer; date)
    return URI(string(base_url, path, "/", name))
end

_dateformat(::Type{<:NCEP}) = DateFormat("yyyymmdd")
