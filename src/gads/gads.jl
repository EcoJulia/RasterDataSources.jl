const GADS_URI = URI(scheme="https", host="zenodo.org", path="/records/19246341/files")

@doc """
    GADS <: RasterDataSource

A global 5-degree gridded product of spectral aerosol optical depths, derived from the
Global Aerosol Data Set (Koepke et al. 1997) via the NicheMapR R package.

The dataset provides climatological aerosol optical properties for a global 5-degree grid
based on measurements and models of 11 aerosol components. It covers two representative
seasons (summer and winter, Northern Hemisphere) and a range of relative humidity conditions.

The file `gads.nc` contains a single variable `OPTDEPTH` with dimensions:
- **Longitude**: 72 points (−180° to 175°, 5° resolution)
- **Latitude**: 37 points (−90° to 90°, 5° resolution)
- **Relative humidity**: 8 levels (0, 50, 70, 80, 90, 95, 98, 99%)
- **Season**: 2 values (0 = NH summer/July, 1 = NH winter/January)
- **Wavelength**: 25 bands (250–4000 nm)

See: [zenodo.org/records/19246341](https://zenodo.org/records/19246341) and
[github.com/mrke/Global-Aerosol-Data-Set](https://github.com/mrke/Global-Aerosol-Data-Set)

Reference: Koepke, P., Hess, M., Schult, I., and Shettle, E.P. (1997). Global Aerosol Data Set.
MPI-Report No. 243, Max-Planck-Institut für Meteorologie, Hamburg.

# Usage with `getraster`
    getraster(source::Type{GADS})

# Example
```julia
julia> getraster(GADS)
"/path/to/storage/GADS/gads.nc"
```

Returns the filepath of the downloaded or pre-existing file.
""" GADS
struct GADS <: RasterDataSource end

getraster_keywords(::Type{GADS}) = ()

rastername(::Type{GADS}) = "gads.nc"
rasterpath(T::Type{GADS}) = joinpath(rasterpath(), "GADS", rastername(T))
rasterurl(T::Type{GADS}) = joinpath(GADS_URI, rastername(T))

function getraster(T::Type{GADS})
    _maybe_download(rasterurl(T), rasterpath(T))
end
