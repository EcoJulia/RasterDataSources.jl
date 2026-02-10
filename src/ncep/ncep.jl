
# Define category types for NCEP datasets that reflect the directory structure
abstract type NCEPCategory end
struct SixHourlyPressure <: NCEPCategory end
struct SixHourlySurface <: NCEPCategory end
struct DailyPressure <: NCEPCategory end
struct DailySurface <: NCEPCategory end
struct DailySurfaceReanalysis2 <: NCEPCategory end
struct MonthlyPressure <: NCEPCategory end
struct MonthlySurface <: NCEPCategory end
struct SurfaceGauss <: NCEPCategory end

"""
    NCEP{C<:NCEPCategory} <: RasterDataSource

Data from the NCEP/NCAR Reanalysis 1 (1948-Present) and NCEP/DOE Reanalysis 2 (1979-Present) datasets.

See: https://psl.noaa.gov/data/gridded/data.ncep.reanalysis.html

# Type Parameters
- `C`: The category of data to download. One of `SixHourlyPressure`, `SixHourlySurface`,
  `DailyPressure`, `DailySurface`, `DailySurfaceReanalysis2`, `MonthlyPressure`,
  `MonthlySurface`, or `SurfaceGauss`.

## Usage

```julia
getraster(NCEP{<category>}, layer; date, dataset)
```

# Keywords
- `date`: A `Date` or `DateTime` object. The year is used to select the file for daily data.
- `dataset`: "reanalysis" or "reanalysis2". Defaults to "reanalysis".

# Layers
| Layer Symbol | Description | Units | Categories |
| :--- | :--- | :--- | :--- |
| `:tmax` | Max Temperature | K | `SurfaceGauss` |
| `:tmin` | Min Temperature | K | `SurfaceGauss` |
| `:air_2m` | Air Temperature (2m) | K | `SurfaceGauss` |
| `:shum_2m` | Specific Humidity (2m) | kg/kg | `SurfaceGauss` |
| `:prate` | Precipitation Rate | Kg/m²/s | `SurfaceGauss` |
| `:pres` | Pressure | Pa | `SurfaceGauss` |
| `:dswrf` | Downward Shortwave Flux | W/m² | `SurfaceGauss` |
| `:dlwrf` | Downward Longwave Flux | W/m² | `SurfaceGauss` |
| `:ulwrf` | Upward Longwave Flux | W/m² | `SurfaceGauss` |
| `:uwnd_10m` | U-Wind (10m) | m/s | `SurfaceGauss` |
| `:vwnd_10m` | V-Wind (10m) | m/s | `SurfaceGauss` |
| `:tcdc` | Total Cloud Cover | % | `SurfaceGauss` (2005 only) |
| `:hgt` | Geopotential Height | m | `SixHourlyPressure`, `DailyPressure`, `MonthlyPressure` |
| `:rhum` | Relative Humidity | % | `SixHourlyPressure`, `DailyPressure`, `MonthlyPressure` |
| `:shum` | Specific Humidity | kg/kg | `SixHourlyPressure`, `DailyPressure`, `MonthlyPressure` |
| `:air` | Air Temperature | K | `SixHourlyPressure`, `DailyPressure`, `MonthlyPressure` |
| `:uwnd` | U-Wind | m/s | `SixHourlyPressure`, `DailyPressure`, `MonthlyPressure` |
| `:vwnd` | V-Wind | m/s | `SixHourlyPressure`, `DailyPressure`, `MonthlyPressure` |
| `:omega` | Vertical Velocity | Pa/s | `SixHourlyPressure`, `DailyPressure`, `MonthlyPressure` |
| `:slp` | Sea Level Pressure | Pa | `DailySurface`, `MonthlySurface` |
| `:pr_wtr` | Precipitable Water | kg/m² | `SixHourlySurface`, `MonthlySurface` |
| `:pres_sfc` | Surface Pressure | Pa | `SixHourlySurface`, `DailySurfaceReanalysis2` |
| `:lftx` | Surface Lifted Index | K | `SixHourlySurface` |
| `:mslp` | Mean Sea Level Pressure | Pa | `DailySurfaceReanalysis2` |
| `:pres_sfc` | Surface Pressure | Pa | `DailySurfaceReanalysis2` |
| `:pr_wtr_eatm`| Precipitable Water | kg/m² | `DailySurfaceReanalysis2` |

# Example
```julia
getraster(NCEP{DailyPressure}, :hgt; date=Date(2001), dataset="reanalysis")
```
"""
struct NCEP{C<:NCEPCategory} <: RasterDataSource end

# Mappings from user-friendly layer names to filename parts
const SIXHOURLY_PRESSURE_MAP = (hgt = "hgt", rhum = "rhum", shum = "shum", air = "air", uwnd = "uwnd", vwnd = "vwnd", omega = "omega")
const SIXHOURLY_SURFACE_MAP = (pr_wtr = "pr_wtr.eatm", pres_sfc = "pres.sfc", lftx = "lftx.sfc")
const SURFACEGAUSS_MAP = (tmax = "tmax.2m.gauss", tmin = "tmin.2m.gauss", air_2m = "air.2m.gauss", shum_2m = "shum.2m.gauss", prate = "prate.sfc.gauss", pres = "pres.sfc.gauss", dswrf = "dswrf.sfc.gauss", dlwrf = "dlwrf.sfc.gauss", ulwrf = "ulwrf.sfc.gauss", uwnd_10m = "uwnd.10m.gauss", vwnd_10m = "vwnd.10m.gauss", tcdc = "tcdc.eatm.gauss")
const DAILY_PRESSURE_MAP = (hgt = "hgt", rhum = "rhum", shum = "shum", air = "air", uwnd = "uwnd", vwnd = "vwnd", omega = "omega")
const DAILY_SURFACE_MAP = (slp = "slp",)
const DAILY_SURFACE_REANALYSIS2_MAP = (mslp = "mslp", pres_sfc = "pres.sfc", pr_wtr_eatm = "pr_wtr.eatm")
const MONTHLY_PRESSURE_MAP = (hgt = "hgt", rhum = "rhum", shum = "shum", air = "air", uwnd = "uwnd", vwnd = "vwnd", omega = "omega")
const MONTHLY_SURFACE_MAP = (slp = "slp", pr_wtr = "pr_wtr")

# Define the layers for each category using the user-friendly keys
layers(::Type{<:NCEP{SixHourlyPressure}}) = keys(SIXHOURLY_PRESSURE_MAP)
layers(::Type{<:NCEP{SixHourlySurface}}) = keys(SIXHOURLY_SURFACE_MAP)
layers(::Type{<:NCEP{DailyPressure}}) = keys(DAILY_PRESSURE_MAP)
layers(::Type{<:NCEP{DailySurface}}) = keys(DAILY_SURFACE_MAP)
layers(::Type{<:NCEP{DailySurfaceReanalysis2}}) = keys(DAILY_SURFACE_REANALYSIS2_MAP)
layers(::Type{<:NCEP{MonthlyPressure}}) = keys(MONTHLY_PRESSURE_MAP)
layers(::Type{<:NCEP{MonthlySurface}}) = keys(MONTHLY_SURFACE_MAP)
layers(::Type{<:NCEP{SurfaceGauss}}) = keys(SURFACEGAUSS_MAP)

# The data is stored in yearly files for 6-hourly and daily data
date_step(::Type{<:NCEP{<:Union{SixHourlyPressure, SixHourlySurface, DailyPressure, DailySurface, DailySurfaceReanalysis2, SurfaceGauss}}}) = Year(1)
# Monthly data is in single files, so date step is irrelevant for file selection
date_step(::Type{<:NCEP{<:Union{MonthlyPressure, MonthlySurface}}}) = Year(100) # Effectively a single step

getraster(T::Type{<:NCEP}, layer::Union{Tuple,Symbol}; date, dataset="reanalysis") =
    _getraster(T, layer, date, dataset)

getraster_keywords(::Type{<:NCEP}) = (:date, :dataset)

function _getraster(T::Type{<:NCEP}, layer::Union{Tuple,Symbol}, dates::Tuple{<:Any,<:Any}, dataset)
    _getraster(T, layer, date_sequence(T, dates), dataset)
end
function _getraster(T::Type{<:NCEP}, layers::Union{Tuple,Symbol}, dates::AbstractArray, dataset)
    _getraster.(T, Ref(layers), dates, Ref(dataset))
end
function _getraster(T::Type{<:NCEP{C}}, layers::Tuple, date::Dates.TimeType, dataset) where {C}
    _map_layers(T, layers, date, dataset)
end
function _getraster(T::Type{<:NCEP{C}}, layer::Symbol, date::Dates.TimeType, dataset) where {C}
    _check_layer(T, layer)
    raster_path = rasterpath(T, layer; date=date, dataset=dataset)
    mkpath(dirname(raster_path))
    if !isfile(raster_path)
        url = rasterurl(T, layer; date=date, dataset=dataset)
        _maybe_download(url, raster_path)
    end
    return raster_path
end

_get_filename_part(::Type{<:NCEP{SixHourlyPressure}}, layer) = SIXHOURLY_PRESSURE_MAP[layer]
_get_filename_part(::Type{<:NCEP{SixHourlySurface}}, layer) = SIXHOURLY_SURFACE_MAP[layer]
_get_filename_part(::Type{<:NCEP{DailyPressure}}, layer) = DAILY_PRESSURE_MAP[layer]
_get_filename_part(::Type{<:NCEP{DailySurface}}, layer) = DAILY_SURFACE_MAP[layer]
_get_filename_part(::Type{<:NCEP{DailySurfaceReanalysis2}}, layer) = DAILY_SURFACE_REANALYSIS2_MAP[layer]
_get_filename_part(::Type{<:NCEP{MonthlyPressure}}, layer) = MONTHLY_PRESSURE_MAP[layer]
_get_filename_part(::Type{<:NCEP{MonthlySurface}}, layer) = MONTHLY_SURFACE_MAP[layer]
_get_filename_part(::Type{<:NCEP{SurfaceGauss}}, layer) = SURFACEGAUSS_MAP[layer]

# Centralized logic for generating category paths, always using forward slashes
function _category_path(::Type{C}, dataset) where C <: NCEPCategory
    if C == SixHourlyPressure
        return "pressure"
    elseif C == SixHourlySurface
        return "surface"
    elseif C == DailyPressure
        return "Dailies/pressure"
    elseif C == DailySurface || C == DailySurfaceReanalysis2
        return "Dailies/surface"
    elseif C == MonthlyPressure
        return "Monthlies/pressure"
    elseif C == MonthlySurface
        return "Monthlies/surface"
    elseif C == SurfaceGauss
        return dataset == "reanalysis" ? "surface_gauss" : "gaussian_grid"
    else
        throw(ArgumentError("Unknown NCEP category $C"))
    end
end

rasterpath(T::Type{<:NCEP}) = joinpath(rasterpath(), "NCEP")
function rasterpath(T::Type{<:NCEP{C}}, layer; date, dataset) where {C}
    filename_part = _get_filename_part(T, layer)
    # Use forward slashes for the category path to be consistent
    path_parts = split(_category_path(C, dataset), '/')
    joinpath(rasterpath(T), dataset, path_parts..., rastername(T, filename_part; date=date))
end

# Filename depends on the category
rastername(::Type{<:NCEP{<:Union{SixHourlyPressure, SixHourlySurface, DailyPressure, DailySurface, DailySurfaceReanalysis2, SurfaceGauss}}}, filename_part; date) = "$(filename_part).$(year(date)).nc"
rastername(::Type{<:NCEP{<:Union{MonthlyPressure, MonthlySurface}}}, filename_part; date) = "$(filename_part).mon.mean.nc"

function rasterurl(T::Type{<:NCEP{C}}, layer; date, dataset) where {C}
    filename_part = _get_filename_part(T, layer)
    base_url = "https://downloads.psl.noaa.gov/Datasets/ncep.$(dataset)/"
    path = _category_path(C, dataset)
    name = rastername(T, filename_part; date=date)
    uri = URI(base_url)
    # Manually join with forward slashes for the URL
    return URI(string(uri, path, "/", name))
end

_dateformat(::Type{<:NCEP}) = DateFormat("yyyymmdd")
