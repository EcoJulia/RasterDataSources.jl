
using URIs

# Define category types for NCEP datasets that reflect the directory structure
abstract type NCEPCategory end
struct DailyPressure <: NCEPCategory end
struct DailySurface <: NCEPCategory end
struct DailySurfaceReanalysis2 <: NCEPCategory end
struct MonthlyPressure <: NCEPCategory end
struct MonthlySurface <: NCEPCategory end
struct SurfaceGauss <: NCEPCategory end

"""
    NCEP{<:NCEPCategory} <: RasterDataSource

Data from the NCEP/NCAR Reanalysis 1 and NCEP/DOE Reanalysis 2 datasets.

`Reanalysis 1` is a global dataset of atmospheric model output, assimilating past data from 1948 to the present.
`Reanalysis 2` is an improved version that corrected errors and updated physical parameterizations, covering 1979 to the present.

See: https://psl.noaa.gov/data/gridded/data.ncep.reanalysis.html and
     https://psl.noaa.gov/data/gridded/data.ncep.reanalysis2.html

# Characteristics
- **Spatial Resolution:** Varies by variable, typically 2.5° x 2.5° global grids or T62 Gaussian grids (~2.0° x 2.0°).
- **Temporal Resolution:** 6-hourly, daily, and monthly.
- **Time Span:** 1948-Present for Reanalysis 1, 1979-Present for Reanalysis 2.

# Type Parameters
- `C`: The category of data to download. One of `DailyPressure`, `DailySurface`, 
  `DailySurfaceReanalysis2`, `MonthlyPressure`, `MonthlySurface`, or `SurfaceGauss`.

# Usage with `getraster`
    getraster(NCEP{<category>}, layer; date, dataset)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` for `layer`s in the given category.

# Keywords
- `date`: A `Date` or `DateTime` object. The year of the date is used to select the file for daily data.
  For monthly data, the date is ignored as all data is in a single file.
- `dataset`: "reanalysis" or "reanalysis2". Defaults to "reanalysis".

# Layers

## `SurfaceGauss`
| Layer Symbol | Description                      | Units     |
| :----------- | :------------------------------- | :-------- |
| `:tmax`      | Maximum Temperature              | K         |
| `:tmin`      | Minimum Temperature              | K         |
| `:air_2m`    | Air Temperature (at 2m)          | K         |
| `:shum_2m`   | Specific Humidity (at 2m)        | kg/kg     |
| `:prate`     | Precipitation Rate               | Kg/m²/s   |
| `:pres`      | Pressure                         | Pa        |
| `:dswrf`     | Downward Shortwave Radiation Flux| W/m²      |
| `:dlwrf`     | Downward Longwave Radiation Flux | W/m²      |
| `:ulwrf`     | Upward Longwave Radiation Flux   | W/m²      |
| `:uwnd_10m`  | U-Wind (at 10m)                  | m/s       |
| `:vwnd_10m`  | V-Wind (at 10m)                  | m/s       |
| `:tcdc`      | Total Cloud Cover                | %         |

## `DailyPressure` & `MonthlyPressure`
| Layer Symbol | Description                      | Units     |
| :----------- | :------------------------------- | :-------- |
| `:hgt`       | Geopotential Height              | m         |
| `:rhum`      | Relative Humidity                | %         |
| `:shum`      | Specific Humidity                | kg/kg     |
| `:air`       | Air Temperature                  | K         |
| `:uwnd`      | U-Wind                           | m/s       |
| `:vwnd`      | V-Wind                           | m/s       |
| `:omega`     | Vertical Velocity                | Pa/s      |

## `DailySurface` & `MonthlySurface` (reanalysis)
| Layer Symbol | Description                      | Units     |
| :----------- | :------------------------------- | :-------- |
| `:slp`       | Sea Level Pressure               | Pa        |
| `:pr_wtr`    | Precipitable Water               | kg/m²     |

## `DailySurfaceReanalysis2`
| Layer Symbol | Description                      | Units     |
| :----------- | :------------------------------- | :-------- |
| `:mslp`      | Mean Sea Level Pressure          | Pa        |
| `:pres_sfc`  | Surface Pressure                 | Pa        |
| `:pr_wtr_eatm`| Precipitable Water               | kg/m²     |


# Example
```julia
# Get the path to the 2001 daily pressure data for the 'hgt' layer
getraster(NCEP{DailyPressure}, :hgt; date=Date(2001), dataset="reanalysis")
```
"""
struct NCEP{C<:NCEPCategory} <: RasterDataSource end

# Mappings from user-friendly layer names to filename parts
const SURFACEGAUSS_MAP = (tmax = "tmax.2m.gauss", tmin = "tmin.2m.gauss", air_2m = "air.2m.gauss", shum_2m = "shum.2m.gauss", prate = "prate.sfc.gauss", pres = "pres.sfc.gauss", dswrf = "dswrf.sfc.gauss", dlwrf = "dlwrf.sfc.gauss", ulwrf = "ulwrf.sfc.gauss", uwnd_10m = "uwnd.10m.gauss", vwnd_10m = "vwnd.10m.gauss", tcdc = "tcdc.eatm.gauss")
const DAILY_PRESSURE_MAP = (hgt = "hgt", rhum = "rhum", shum = "shum", air = "air", uwnd = "uwnd", vwnd = "vwnd", omega = "omega")
const DAILY_SURFACE_MAP = (slp = "slp", pr_wtr = "pr_wtr")
const DAILY_SURFACE_REANALYSIS2_MAP = (mslp = "mslp", pres_sfc = "pres.sfc", pr_wtr_eatm = "pr_wtr.eatm")
const MONTHLY_PRESSURE_MAP = (hgt = "hgt", rhum = "rhum", shum = "shum", air = "air", uwnd = "uwnd", vwnd = "vwnd", omega = "omega")
const MONTHLY_SURFACE_MAP = (slp = "slp", pr_wtr = "pr_wtr")

# Define the layers for each category using the user-friendly keys
layers(::Type{<:NCEP{DailyPressure}}) = keys(DAILY_PRESSURE_MAP)
layers(::Type{<:NCEP{DailySurface}}) = keys(DAILY_SURFACE_MAP)
layers(::Type{<:NCEP{DailySurfaceReanalysis2}}) = keys(DAILY_SURFACE_REANALYSIS2_MAP)
layers(::Type{<:NCEP{MonthlyPressure}}) = keys(MONTHLY_PRESSURE_MAP)
layers(::Type{<:NCEP{MonthlySurface}}) = keys(MONTHLY_SURFACE_MAP)
layers(::Type{<:NCEP{SurfaceGauss}}) = keys(SURFACEGAUSS_MAP)

# The data is stored in yearly files for daily data
date_step(::Type{<:NCEP{<:Union{DailyPressure, DailySurface, DailySurfaceReanalysis2, SurfaceGauss}}}) = Year(1)
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
        filename_part = _get_filename_part(T, layer)
        url = rasterurl(T, filename_part, date, dataset)
        _maybe_download(url, raster_path)
    end
    return raster_path
end

_get_filename_part(::Type{<:NCEP{DailyPressure}}, layer) = DAILY_PRESSURE_MAP[layer]
_get_filename_part(::Type{<:NCEP{DailySurface}}, layer) = DAILY_SURFACE_MAP[layer]
_get_filename_part(::Type{<:NCEP{DailySurfaceReanalysis2}}, layer) = DAILY_SURFACE_REANALYSIS2_MAP[layer]
_get_filename_part(::Type{<:NCEP{MonthlyPressure}}, layer) = MONTHLY_PRESSURE_MAP[layer]
_get_filename_part(::Type{<:NCEP{MonthlySurface}}, layer) = MONTHLY_SURFACE_MAP[layer]
_get_filename_part(::Type{<:NCEP{SurfaceGauss}}, layer) = SURFACEGAUSS_MAP[layer]

# Centralized logic for generating category paths, always using forward slashes
function _category_path(::Type{C}, dataset) where C <: NCEPCategory
    if C == DailyPressure
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
rastername(::Type{<:NCEP{<:Union{DailyPressure, DailySurface, DailySurfaceReanalysis2, SurfaceGauss}}}, filename_part; date) = "$(filename_part).$(year(date)).nc"
rastername(::Type{<:NCEP{<:Union{MonthlyPressure, MonthlySurface}}}, filename_part; date) = "$(filename_part).mon.mean.nc"

function rasterurl(T::Type{<:NCEP{C}}, filename_part, date, dataset) where {C}
    base_url = "https://downloads.psl.noaa.gov/Datasets/ncep.$(dataset)/"
    path = _category_path(C, dataset)
    name = rastername(T, filename_part; date=date)
    uri = URI(base_url)
    # Manually join with forward slashes for the URL
    return URI(string(uri, path, "/", name))
end

_dateformat(::Type{<:NCEP}) = DateFormat("yyyymmdd")
