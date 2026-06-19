const CPCSOIL_URI = URI(scheme="https", host="psl.noaa.gov",
    path="/thredds/fileServer/Datasets/cpcsoil")

const CPCSOIL_LTM_PERIODS = ("1991-2020", "1981-2010")

"""
    CPCSoilMean

Type parameter for [`CPCSoil`](@ref) selecting the full historical monthly
mean time series (`soilw.mon.mean.v2.nc`, 254 MB) rather than a long-term
mean climatology.

```julia
getraster(CPCSoil{CPCSoilMean})
```
"""
struct CPCSoilMean end

"""
    CPCSoil{X} <: RasterDataSource

Monthly soil moisture data from the NOAA Climate Prediction Center (CPC),
on a global 0.5° grid.

Two products are available:

**Long-term mean (LTM)** — `CPCSoil` (default):
12 monthly climatological means for a selected 30-year period.
Use the `period` keyword to select the climatology:
- `"1991-2020"` (default, 9.5 MB)
- `"1981-2010"` (3.2 MB)

**Historical monthly means** — `CPCSoil{CPCSoilMean}`:
Full monthly time series from 1948 to present (254 MB).

See: [psl.noaa.gov/data/gridded/data.cpcsoil.html](https://psl.noaa.gov/data/gridded/data.cpcsoil.html)

Reference: Fan, Y. and van den Dool, H. (2004). Climate Prediction Center global
monthly soil moisture data set at 0.5° resolution for 1948 to present.
*Journal of Geophysical Research*, 109, D10102.

# Usage with `getraster`
    getraster(source::Type{CPCSoil}; period="1991-2020")
    getraster(source::Type{CPCSoil{CPCSoilMean}})

# Examples
```julia
julia> getraster(CPCSoil)
"/path/to/storage/CPCSoil/soilw.mon.1991-2020.ltm.v2.nc"

julia> getraster(CPCSoil; period="1981-2010")
"/path/to/storage/CPCSoil/soilw.mon.1981-2010.ltm.v2.nc"

julia> getraster(CPCSoil{CPCSoilMean})
"/path/to/storage/CPCSoil/soilw.mon.mean.v2.nc"
```

Returns the filepath of the downloaded or pre-existing file.
"""
struct CPCSoil{X} <: RasterDataSource end

defperiod(::Type{CPCSoil}) = "1991-2020"

function _check_period(::Type{CPCSoil}, period)
    period in CPCSOIL_LTM_PERIODS || throw(ArgumentError(
        "Period \"$period\" is not available. Choose from: $(join(CPCSOIL_LTM_PERIODS, ", "))"
    ))
end

getraster_keywords(::Type{CPCSoil}) = (:period,)

rastername(::Type{CPCSoil}; period) = "soilw.mon.$(period).ltm.v2.nc"

rasterpath(::Type{CPCSoil}) = joinpath(rasterpath(), "CPCSoil")
rasterpath(T::Type{CPCSoil}; period) = joinpath(rasterpath(T), rastername(T; period))

rasterurl(T::Type{CPCSoil}; period) = joinpath(CPCSOIL_URI, rastername(T; period))

function getraster(T::Type{CPCSoil}; period=defperiod(T))
    _check_period(T, period)
    _maybe_download(rasterurl(T; period), rasterpath(T; period))
end

getraster_keywords(::Type{CPCSoil{CPCSoilMean}}) = ()

rastername(::Type{CPCSoil{CPCSoilMean}}) = "soilw.mon.mean.v2.nc"

rasterpath(T::Type{CPCSoil{CPCSoilMean}}) =
    joinpath(rasterpath(), "CPCSoil", rastername(T))

rasterurl(T::Type{CPCSoil{CPCSoilMean}}) =
    joinpath(CPCSOIL_URI, rastername(T))

function getraster(T::Type{CPCSoil{CPCSoilMean}})
    _maybe_download(rasterurl(T), rasterpath(T))
end
