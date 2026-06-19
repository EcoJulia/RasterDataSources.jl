const CRUCL2_URI = URI(scheme="https", host="zenodo.org", path="/records/20754689/files")

"""
    CRUCL2 <: RasterDataSource

Monthly mean climate for the global land surface at 10-minute (~18 km) resolution,
based on station observations from 1961–1990 (CRU CL 2.0).

The file `cru_cl2.nc` contains the following variables with a `month` dimension (1–12),
except `elv` which has no month dimension:

| Variable | Description                  | Units   |
|----------|------------------------------|---------|
| `tmp`    | Mean temperature             | °C      |
| `dtr`    | Diurnal temperature range    | °C      |
| `pre`    | Precipitation                | mm      |
| `rd0`    | Wet-day frequency            | days    |
| `frs`    | Frost-day frequency          | days    |
| `reh`    | Relative humidity            | %       |
| `sunp`   | Sunshine percentage          | %       |
| `wnd`    | Wind speed                   | m/s     |
| `elv`    | Elevation                    | m       |

Minimum and maximum temperature can be derived as `tmp ± dtr/2`.

See: [zenodo.org/records/20754689](https://zenodo.org/records/20754689) and
[github.com/mrke/CRU-CL-2](https://github.com/mrke/CRU-CL-2)

Reference: New, M., Lister, D., Hulme, M. and Makin, I., 2002. A high-resolution data set of
surface climate over global land areas. *Climate Research*, 21: 1–25.

# Usage with `getraster`
    getraster(source::Type{CRUCL2})

# Example
```julia
julia> getraster(CRUCL2)
"/path/to/storage/CRUCL2/cru_cl2.nc"
```

Returns the filepath of the downloaded or pre-existing file.
"""
struct CRUCL2 <: RasterDataSource end

getraster_keywords(::Type{CRUCL2}) = ()

rastername(::Type{CRUCL2}) = "cru_cl2.nc"
rasterpath(T::Type{CRUCL2}) = joinpath(rasterpath(), "CRUCL2", rastername(T))
rasterurl(T::Type{CRUCL2}) = joinpath(CRUCL2_URI, rastername(T))

function getraster(T::Type{CRUCL2})
    _maybe_download(rasterurl(T), rasterpath(T))
end
