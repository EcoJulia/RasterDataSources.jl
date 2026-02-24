
const ERA5_URI = URI(scheme="https", host="nsf-ncar-era5.s3.us-west-2.amazonaws.com")

# Docs below
struct ERA5 <: RasterDataSource end

# Map layer symbols to (table, param, shortname) tuples
const ERA5_LAYER_CODES = (
    t2m = (128, 167, "2t"),           # 2m temperature
    d2m = (128, 168, "2d"),           # 2m dewpoint temperature
    u10 = (128, 165, "10u"),          # 10m U wind component
    v10 = (128, 166, "10v"),          # 10m V wind component
    u100 = (228, 246, "100u"),        # 100m U wind component
    v100 = (228, 247, "100v"),        # 100m V wind component
    sp = (128, 134, "sp"),            # Surface pressure
    msl = (128, 151, "msl"),          # Mean sea level pressure
    skt = (128, 235, "skt"),          # Skin temperature
    sst = (128, 34, "sstk"),          # Sea surface temperature
    sd = (128, 141, "sd"),            # Snow depth
    swvl1 = (128, 39, "swvl1"),       # Soil water volume layer 1
    swvl2 = (128, 40, "swvl2"),       # Soil water volume layer 2
    swvl3 = (128, 41, "swvl3"),       # Soil water volume layer 3
    swvl4 = (128, 42, "swvl4"),       # Soil water volume layer 4
    stl1 = (128, 139, "stl1"),        # Soil temperature layer 1
    stl2 = (128, 170, "stl2"),        # Soil temperature layer 2
    stl3 = (128, 183, "stl3"),        # Soil temperature layer 3
    stl4 = (128, 236, "stl4"),        # Soil temperature layer 4
    tcc = (128, 164, "tcc"),          # Total cloud cover
    lcc = (128, 186, "lcc"),          # Low cloud cover
    mcc = (128, 187, "mcc"),          # Medium cloud cover
    hcc = (128, 188, "hcc"),          # High cloud cover
    cape = (128, 59, "cape"),         # CAPE
    blh = (128, 159, "blh"),          # Boundary layer height
    tcwv = (128, 137, "tcwv"),        # Total column water vapour
    tco3 = (128, 206, "tco3"),        # Total column ozone
)

layers(::Type{ERA5}) = keys(ERA5_LAYER_CODES)

# Product type for surface analysis
const ERA5_PRODUCT = "e5.oper.an.sfc"

date_step(::Type{ERA5}) = Month(1)

@doc """
    ERA5 <: RasterDataSource

Data from the ERA5 reanalysis dataset, hosted on AWS Open Data (NSF NCAR mirror).

See: [registry.opendata.aws/nsf-ncar-era5](https://registry.opendata.aws/nsf-ncar-era5/)

The dataset contains NetCDF files with hourly data at 0.25° resolution.
Each file covers one month and one variable.

The available layers are: `$(layers(ERA5))`.

Common layers:
- `:t2m` - 2m temperature
- `:d2m` - 2m dewpoint temperature
- `:u10`, `:v10` - 10m wind components
- `:u100`, `:v100` - 100m wind components
- `:sp` - Surface pressure
- `:msl` - Mean sea level pressure
- `:skt` - Skin temperature
- `:sst` - Sea surface temperature
- `:tcc` - Total cloud cover

Data is available from 1940 to present (with 3-4 month lag), updated monthly.

`getraster` for `ERA5` must use a `date` keyword to specify the year and month to download.

# Usage with `getraster`
    getraster(source::Type{ERA5}, [layer]; date)

Download ERA5 data for the specified date.

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(layers(ERA5))`.
    Without a `layer` argument, all layers will be downloaded, and a `NamedTuple` of paths returned.

# Keywords
- `date`: a `DateTime`, `AbstractVector` of `DateTime` or a `Tuple` of start and end dates.
    For multiple dates, a `Vector` of multiple filenames will be returned.

# Example
```julia
julia> getraster(ERA5, :t2m; date=Date(2020, 1))
"/path/to/storage/ERA5/e5.oper.an.sfc/202001/e5.oper.an.sfc.128_167_2t.ll025sc.2020010100_2020013123.nc"
```

Returns the filepath/s of the downloaded or pre-existing files.
""" ERA5

function getraster(T::Type{ERA5}, layers::Union{Tuple,Symbol}; date)
    _getraster(T, layers, date)
end

getraster_keywords(::Type{ERA5}) = (:date,)

function _getraster(T::Type{ERA5}, layers, dates::Tuple{<:Any,<:Any})
    _getraster(T, layers, date_sequence(T, dates))
end
function _getraster(T::Type{ERA5}, layers, dates::AbstractArray)
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{ERA5}, layers::Tuple, date::Dates.TimeType)
    _map_layers(T, layers, date)
end
function _getraster(T::Type{ERA5}, layer::Symbol, date::Dates.TimeType)
    _check_layer(T, layer)
    mkpath(rasterpath(T, date))
    url = rasterurl(T, layer; date=date)
    path = rasterpath(T, layer; date=date)
    _maybe_download(url, path)
    path
end

_lastday(date::Dates.TimeType) = Dates.daysinmonth(date)
_yearmonth(date::Dates.TimeType) = "$(year(date))$(lpad(month(date), 2, '0'))"

# File naming: e5.oper.an.sfc.128_167_2t.ll025sc.2020010100_2020013123.nc
function rastername(::Type{ERA5}, layer::Symbol; date)
    table, param, shortname = ERA5_LAYER_CODES[layer]
    ym = _yearmonth(date)
    startdate = "$(ym)0100"
    enddate = "$ym$(_lastday(date))23"
    "$ERA5_PRODUCT.$(table)_$(lpad(param, 3, '0'))_$shortname.ll025sc.$(startdate)_$enddate.nc"
end

# Paths
rasterpath(::Type{ERA5}) = joinpath(rasterpath(), "ERA5")
rasterpath(::Type{ERA5}, date::Dates.TimeType) = joinpath(rasterpath(ERA5), ERA5_PRODUCT, _yearmonth(date))
rasterpath(T::Type{ERA5}, layer::Symbol; date) =
    joinpath(rasterpath(T, date), rastername(T, layer; date))

# URLs
rasterurl(::Type{ERA5}, layer::Symbol; date) =
    joinpath(ERA5_URI, ERA5_PRODUCT, _yearmonth(date), rastername(ERA5, layer; date))
