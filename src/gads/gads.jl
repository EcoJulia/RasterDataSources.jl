const GADS_URI = URI(scheme="https", host="zenodo.org", path="/records/19246341/files")

const GADS_LAYERS = (
    optdepth = (description="Spectral aerosol optical depth", units="dimensionless"),
)

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

The available layers are: `$(keys(GADS_LAYERS))`.

# Usage with `getraster`
    getraster(source::Type{GADS}, [layer])

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(keys(GADS_LAYERS))`.
    Without a `layer` argument all layers are downloaded and a `NamedTuple` of paths returned.

# Example
```julia
julia> getraster(GADS, :optdepth)
"/path/to/storage/GADS/gads.nc"

julia> getraster(GADS)
(optdepth = "/path/to/storage/GADS/gads.nc",)
```

Returns the filepath/s of the downloaded or pre-existing files.
""" GADS
struct GADS <: RasterDataSource end

layers(::Type{GADS}) = keys(GADS_LAYERS)
getraster_keywords(::Type{GADS}) = ()

rastername(::Type{GADS}, layer::Symbol) = "gads.nc"

rasterpath(::Type{GADS}) = joinpath(rasterpath(), "GADS")
rasterpath(T::Type{GADS}, layer::Symbol) = joinpath(rasterpath(T), rastername(T, layer))

rasterurl(T::Type{GADS}, layer::Symbol) = joinpath(GADS_URI, rastername(T, layer))

function getraster(T::Type{GADS}, layers::Union{Tuple,Symbol})
    _getraster(T, layers)
end

function _getraster(T::Type{GADS}, layers::Tuple)
    _map_layers(T, layers)
end

function _getraster(T::Type{GADS}, layer::Symbol)
    _check_layer(T, layer)
    path = rasterpath(T, layer)
    url  = rasterurl(T, layer)
    _maybe_download(url, path)
end
