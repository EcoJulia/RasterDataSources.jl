# Exported

"""
    getraster(source::Type, [layer]; kw...)

Download raster layers `layers` from the data `source`,
returning a `String` for a single layer, or a `NamedTuple`
for a `Tuple` of layers. 

`getraster` provides a standardised interface to download data sources,
and return the filename/s of the selected files.

`getraster` can be called with any `RasterDataSource`. See the docstrings of these types
for the specific keywords and arguments. `RasterDataSource` with documented `getraster` usage are
[`WorldClim`](@ref), [`EarthEnv`](@ref), [`CHELSA`](@ref), [`AWAP`](@ref), [`ALWB`](@ref), 
and [`MODIS`](@ref). All these implementations follow the template specified below.

# Arguments

- `source`: defines the [`RasterDataSource`](@ref) and (if it there is more than one)
    the specific [`RasterDataSet`](@ref) from which to download data.
- `layer`: choose the named `Symbol`/s or numbered `Int`/s (for `BioClim`) layer/s of the 
    data source. If `layer` is not passed, all layers will be downloaded, returning a 
    `NamedTuple` of filenames.

# Keywords

Keyword arguments specify subsets of a data set, such as by date or resolution.
As much as possible these are standardised for all sources where they are relevent.

- `date`: `DateTime` date, range of dates, or tuple of start and end dates. Usually for weather datasets.
- `month`: month or range of months to download for climatic datasets, as `Integer`s from 1 to 12.
- `res`: spatial resolion of the file, as a `String` with units, e.g. "10m".

# Return values

The return value is either a single `String`, a `Tuple/Array` of `String`, or a
`Tuple/Array` of `Tuple/Array` of `String` --- depending on the arguments. If multiple
layers are specified, this may return multiple filenames. If multiple months or dates are
specified, this may also return multiple filenames.

Keyword arguments depend on the specific data source. 
They may modify the return value, following a pattern:
- `month` keywords of `AbstractArray` will return a `Vector{String}`
    or `Vector{<:NamedTuple}`.
- `date` keywords of `AbstractArray` will return a `Vector{String}` or
    `Vector{<:NamedTuple}`.
- `date` keywords of `Tuple{start,end}` will take all the dates between the 
    start and end dates as a `Vector{String}` or `Vector{<:NamedTuple}`.

Where `date` and `month` keywords coexist, `Vector{Vector{String}}` of
`Vector{Vector{NamedTuple}}` is the result. `date` ranges are always
the outer `Vector`, `month` the inner `Vector` with `layer` tuples as
the inner `NamedTuple`. No other keywords can be `Vector`.
"""
function getraster end

# Not exported, but relatively consistent and stable
# These should be used for consistency accross all sources

"""
    rastername(source::Type, [layer]; kw...)

Returns the name of the file, without downloading it.

Arguments are the same as for `getraster`

Returns a `String` or multiple `Strings`.
"""
function rastername end

"""
    rasterpath(source::Type, [layer]; kw...)

Returns the name of the file, without downloading it.

Arguments are the same as for `getraster`

Returns a `String` or multiple `Strings`.
"""
function rasterpath end

"""
    rasterurl(source::Type, [layer]; kw...)

If the file has a single url, returns it without downloading.

Arguments are the same as for `getraster`.

Returns a URIs.jl `URI` or mulitiple `URI`s.
"""
function rasterurl end

"""
    zipname(source::Type, [layer]; kw...)

If the url is a zipped file, returns its name.

Arguments are as the same for `getraster` where possible.

Returns a `String` or multiple `Strings`.
"""
function zipname end

"""
    zippath(source::Type, [layer]; kw...)

If the url is a zipped file, returns its path when downloaded.
(This may not exist after extraction with `getraster`)

Arguments are the same as for `getraster` where possible.

Returns a `String` or multiple `Strings`.
"""
function zippath end

"""
    zipurl(source::Type, [layer]; kw...)

If the url is a zipped file, returns its zip path without downloading.

Arguments are the same as for `getraster` where possible.

Returns a URIs.jl `URI` or mulitiple `URI`s.
"""
function zipurl end

"""
    WorldClim{Union{BioClim,Climate,Elevation,Weather,<:Future}} <: RasterDataSource

Data from WorldClim datasets, either [`BioClim`](@ref), [`Climate`](@ref), 
[`Weather`](@ref), [`Climate`](@ref), or [`Future`](@ref) variables for current and future conditions.

Future variables are available for `BioClim` and `Climate` data. See the docstring of `Future` for available model choices
    and implementation details.

See: [www.worldclim.org](https://www.worldclim.org)

# Usage with `getraster`
    getraster(T::Type{WorldClim{BioClim}}, [layer::Union{Tuple,Int,Symbol}]; res)
    getraster(T::Type{WorldClim{Climate}}, [layer::Union{Tuple,Symbol}]; month, res)
    getraster(T::Type{WorldClim{Elevation}}; res)
    getraster(T::Type{WorldClim{Weather}}, [layer::Union{Tuple,Symbol}]; date)
    getraster(T::Type{WorldClim{Future}}, [layer]; date, res) => String

## Arguments

- `layer`: `Integer`, `Symbol` or tuple/range of these. Without a `layer` argument, all layers
    will be downloaded, and a `NamedTuple` of paths returned. Available layers are:
    - `BioClim`: Integers $(first(layers(BioClim))) to $(last(layers(BioClim))) 
        or Symbols :$(first(layerkeys(BioClim))) to :$(last(layerkeys(BioClim)))
    - `Climate`: $(layers(WorldClim{Climate}))
    - `Elevation`: Only has a single layer, :elev
    - `Weather`: $(layers(WorldClim{Weather}))
    - `Future{Climate}`: $(layers(WorldClim{Future{Climate}}))

## Keywords

- `res`: `String` chosen from $(resolutions(WorldClim{BioClim})), "10m" by default.
- `month`: `Integer` or `AbstractArray` of `Integer`. Chosen from `1:12`.
- `date`: a `Date` or `DateTime` object, a `Vector` of dates, or `Tuple` of start/end dates.
    `WorldClim{Weather}` is available with a daily timestep. Future data is available in 20-year intervals from 2021 to 2100.

## Examples
```julia
using RasterDataSources, Dates
bio_current = getraster(WorldClim{BioClim}, res = "5m")
bio_future = getraster(WorldClim{Future{BioClim, CMIP6, GFDL_ESM4, SSP370}}, date = Date(2050), res = "5m")
```
"""
WorldClim

"""
TODO
"""
CRU

"""
    EarthEnv{Union{HabitatHeterogeneity,LandCover}} <: RasterDataSource

Data from the `EarthEnv` including `HabitatHeterogeneity` and `LandCover`

See: [www.earthenv.org](http://www.earthenv.org/)

# Usage with `getraster`
    getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, [layer]; res="25km")
    getraster(T::Type{EarthEnv{LandCover}}, [layer]; discover=false)

Download [`EarthEnv`](@ref) habitat heterogeneity data.

# Arguments
- `layer`: `Integer`, `Symbol` or tuple/range of these. Without a `layer` argument, all layers
    will be downloaded, and a `NamedTuple` of paths returned. Available layers are:
    - `HabitatHeterogeneity`: $(layers(EarthEnv{HabitatHeterogeneity}))
    - `LandCover`: Integers $(first(layers(EarthEnv{LandCover}))) to $(last(layers(EarthEnv{LandCover}))) or 
        Symbols $(layerkeys(EarthEnv{LandCover}))

# Keywords
- `res`: `String` chosen from `$(resolutions(EarthEnv{HabitatHeterogeneity}))`, defaulting to "25km".
- `discover::Bool`: whether to download the dataset that integrates the DISCover model.

Returns the filepath/s of the downloaded or pre-existing files.
"""
EarthEnv

"""
    CHELSA{Union{BioClim,BioClimPlus,Climate,<:Future}} <: RasterDataSource

Data from CHELSA, currently implements the `BioClim`, `BioClimPlus`, and `Climate`
variables for current and future conditions. 

See: [chelsa-climate.org](https://chelsa-climate.org/) for the dataset,
and the [`getraster`](@ref) docs for implementation details.

# Usage with `getraster`
    getraster(source::Type{CHELSA{BioClim}}, [layer]; [version], [patch])
    getraster(source::Type{CHELSA{BioClimPlus}}, [layer]; [version], [patch])
    getraster(T::Type{CHELSA{Climate}}, [layer]; month)
    getraster(T::Type{CHELSA{Future{BioClim}}}, [layer]; date
    getraster(T::Type{CHELSA{Future{Climate}}}, [layer]; date, month)

Download [`CHELSA`](@ref) [`BioClim`](@ref) data from [chelsa-climate.org](https://chelsa-climate.org/).

## Arguments
- `layer`: `Integer`, `Symbol` or tuple/range of these. Without a `layer` argument, all layers
    will be downloaded, and a `NamedTuple` of paths returned. Available layers are:
    - `BioClim`: Integers $(first(layers(BioClim))) to $(last(layers(BioClim))) or 
        Symbols :$(first(layerkeys(BioClim))) to :$(last(layerkeys(BioClim)))
    - `BioClimPlus`: Includes `BioClim` layers and many additional layers. See `RasterDataSources.layers(BioClimPlus)`.
    - `Climate`: $(layers(CHELSA{Climate}))

## Keyword arguments
- `version`: `Integer` indicating the CHELSA version, currently either `1` or `2`. Defaults to 2.
- `patch`: `Integer` indicating the CHELSA patch number. Defaults to the latest patch (V1.2 and V2.1)
- `month`: `Integer` or `AbstractArray` of `Integer`. Chosen from `1:12`.
- `date`: a `Date` or `DateTime` object, a Vector, or Tuple of start/end dates.
    Note that CHELSA CMIP5 only has two datasets, for the periods 2041-2060 and
    2061-2080. CMIP6 has datasets for the periods 2011-2040, 2041-2070, and 2071-2100.
    Dates must fall within these ranges.
    
## Example
```julia
using RasterDataSources, Dates
getraster(CHELSA{Future{BioClim, CMIP6, GFDL_ESM4, SSP370}}, 1, date = Date(2050))
```
"""
CHELSA

"""
    Future{<:RasterDataSet,<:CMIPphase,<:ClimateModel,<:ClimateScenario}

Future climate datasets specified with a dataset, phase, model, and scenario.

## Type Parameters

#### `RasterDataSet`

Currently [`BioClim`](@ref) and [`Climate`](@ref) are implemented
for [`CHELSA`](@ref) and [`WorldClim`](@ref). Future WorldClim is only available 
for CMIP6.

#### `CMIPphase`

Can be either [`CMIP5`](@ref) or [`CMIP6`](@ref).

#### `ClimateModel`

Climate models can be chosen from: 

`$(join(CMIP5_MODELS, "`,  `"))` for `CMIP5`;

`$(join(CMIP6_MODELS, "`,  `"))` for `CMIP6`;"

#### `ClimateScenario`

CMIP5 Climate scenarios are all [`RepresentativeConcentrationPathway`](@ref)
and can be chosen from: `RCP26`, `RCP45`, `RCP60`, `RCP85`

CMIP6 Climate scenarios are all [`SharedSocioeconomicPathway`](@ref) and
can be chosen from: `SSP126`, `SSP245`, `SSP370`, `SSP585`

However, note that not all climate scenarios are available for all models.

## Example

```jldoctest future
using RasterDataSources
datasource = CHELSA{Future{BioClim, CMIP5, GFDL_ESM4, SSP370}}
```

"""
Future