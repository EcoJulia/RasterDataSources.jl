"""
    RasterDataSource 

Abstract supertype for raster data collections.  
"""
abstract type RasterDataSource end

"""
    RasterDataSet

Abstract supertype for datasets that belong to a [`RasterDataSource`](@ref).
"""
abstract type RasterDataSet end

"""
    BioClim <: RasterDataSet

BioClim datasets. Usually containing layers from `1:19`. 
These can also be accessed with `:bioX`, e.g. `:bio5`.

They do not usually use `month` or `date` keywords, but may use
`date` in past/future scenarios. 

Currently implemented for WorldClim and CHELSA as `WorldClim{BioClim}`,
`CHELSA{BioClim}` and `CHELSA{Future{BioClim, args..}}`.

See the [`getraster`](@ref) docs for implementation details.
"""
struct BioClim <: RasterDataSet end

# Bioclim has standardised layers for all data sources
layers(::Type{BioClim}) = values(bioclim_lookup)
layerkeys(T::Type{BioClim}) = keys(bioclim_lookup)
layerkeys(T::Type{BioClim}, layer) = bioclim_key(layer)
layerkeys(T::Type{BioClim}, layers::Tuple) = map(l -> bioclim_key(l), layers)

const bioclim_lookup = (
    bio1 = 1,
    bio2 = 2,
    bio3 = 3,
    bio4 = 4,
    bio5 = 5,
    bio6 = 6,
    bio7 = 7,
    bio8 = 8,
    bio9 = 9,
    bio10 = 10,
    bio11 = 11,
    bio12 = 12,
    bio13 = 13,
    bio14 = 14,
    bio15 = 15,
    bio16 = 16,
    bio17 = 17,
    bio18 = 18,
    bio19 = 19,
)

# We allow a range of bioclim keys, as they are listed with 
# a lot of variants on CHELSA and WorldClim
bioclim_key(k::Symbol) = bioclim_key(string(k))
bioclim_key(k::AbstractString) = Symbol(replace(lowercase(k), "_" => ""))
bioclim_key(k::Integer) = keys(bioclim_lookup)[k]

bioclim_int(k::Integer) = k
bioclim_int(k::Symbol) = bioclim_lookup[bioclim_key(k)]

"""
    BioClimPlus <: RasterDataSet

Extended BioClim datasets, available from CHELSA. 
More information on the CHELSA website: https://chelsa-climate.org/exchelsa-extended-bioclim/

Some of these are available as average annual maximum, minimum, mean, and range. 
Others have a single value, more like the regular BioClim variables.

They do not usually use `month` or `date` keywords, but may use
`date` in past/future scenarios. 

Currently implemented for CHELSA as `CHELSA{BioClim}` and `CHELSA{Future{BioClim, args..}}`,
specifying layer names as `Symbol`s.

See the [`getraster`](@ref) docs for implementation details.
"""
struct BioClimPlus <: RasterDataSet end

const _BIOCLIMPLUS_MONTHLY = vec([Symbol("$(b)_$(m)") for b in (:hurs, :clt, :sfcWind, :vpd, :rsds, :pet_penman, :cmi), m in [:max, :min, :mean, :range]])
const _BIOCLIMPLUS_GDD = vec([Symbol("$b$d") for b in (:gdd, :gddlgd, :gdgfgd, :ngd), d in [0, 5, 10]])
const _BIOCLIMPLUS_OTHERS = (:fcf, :fgd, :lgd, :scd, :gsl, :gst, :gsp, :npp, :swb, :swe)
const BIOCLIMPLUS_LAYERS = [
    collect(layerkeys(BioClim))
    _BIOCLIMPLUS_MONTHLY;
    _BIOCLIMPLUS_GDD;
    collect(_BIOCLIMPLUS_OTHERS);
    [Symbol("kg$i") for i in 0:5];
]

const BIOCLIMPLUS_LAYERS_FUTURE = [
    collect(layerkeys(BioClim));
    _BIOCLIMPLUS_GDD;
    collect(filter(!=(:swb), _BIOCLIMPLUS_OTHERS))
    [Symbol("kg$i") for i in 0:5];
]

layers(::Type{BioClimPlus}) = BIOCLIMPLUS_LAYERS

"""
    Climate <: RasterDataSet

Climate datasets. These are usually months of the year, not specific dates,
and use a `month` keyword in `getraster`. They also use `date` in past/future scenarios.

Currently implemented for WorldClim and CHELSA as `WorldClim{Climate}`,
`CHELSA{Climate}` and `CHELSA{Future{Climate, args..}}`.

See the [`getraster`](@ref) docs for implementation details.
"""
struct Climate <: RasterDataSet end

months(::Type{Climate}) = ntuple(identity, Val{12})

"""
    Weather <: RasterDataSet

Weather datasets. These are usually large time-series of specific dates,
and use a `date` keyword in `getraster`.

Currently implemented for WorldClim and CHELSA as `WorldClim{Weather}`,
and `CHELSA{Weather}`

See the [`getraster`](@ref) docs for implementation details.
"""
struct Weather <: RasterDataSet end

"""
    Elevation <: RasterDataSet

Elevation datasets. 

Currently implemented for WorldClim as `WorldClim{Elevation}`.

See the [`getraster`](@ref) docs for implementation details.
"""
struct Elevation <: RasterDataSet end

"""
    LandCover <: RasterDataSet

Land-cover datasets.

Currently implemented for EarthEnv as `EarchEnv{LandCover}`.

See the [`getraster`](@ref) docs for implementation details.
"""
struct LandCover{X} <: RasterDataSet end

"""
    HabitatHeterogeneity <: RasterDataSet

Habitat heterogeneity datasets.

Currently implemented for EarchEnv as `EarchEnv{HabitatHeterogeneity}`.

See the [`getraster`](@ref) docs for implementation details.
"""
struct HabitatHeterogeneity <: RasterDataSet end

"""
    CMIPphase 

Abstract supertype for phases of the CMIP,
the Coupled Model Intercomparison Project.

Subtypes are `CMIP5` and `CMIP6`.
"""
abstract type CMIPphase end

"""
    CMIP5 <: CMIPphase

The Coupled Model Intercomparison Project, Phase 5.
"""
struct CMIP5 <: CMIPphase end

"""
    CMIP6 <: CMIPphase

The Coupled Model Intercomparison Project, Phase 6.
"""
struct CMIP6 <: CMIPphase end

"""
    ClimateModel

Abstract supertype for climate models use in [`Future`](@ref) datasets.
"""
abstract type ClimateModel{CMIP<:CMIPphase} end
const CMIP6_MODELS = Type{<:ClimateModel{CMIP6}}[]
const CMIP5_MODELS = Type{<:ClimateModel{CMIP5}}[]

"""
    ClimateScenario 

Abstract supertype for scenarios used in [`CMIPphase`](@ref) models.
"""
abstract type ClimateScenario end

"""
    RepresentativeConcentrationPathway

Abstract supertype for Representative Concentration Pathways (RCPs) for [`CMIP5`](@ref).

Subtypes are: `RCP26`, `RCP45`, `RCP60`, `RCP85`
"""
abstract type RepresentativeConcentrationPathway <: ClimateScenario end

struct RCP26 <: RepresentativeConcentrationPathway end
struct RCP45 <: RepresentativeConcentrationPathway end
struct RCP60 <: RepresentativeConcentrationPathway end
struct RCP85 <: RepresentativeConcentrationPathway end

"""
    SharedSocioeconomicPathway

Abstract supertype for Shared Socio-economic Pathways (SSPs) for [`CMIP6`](@ref).

Subtypes are: `SSP126`, `SSP245`, SSP370`, SSP585`
"""
abstract type SharedSocioeconomicPathway <: ClimateScenario end

struct SSP126 <: SharedSocioeconomicPathway end
struct SSP245 <: SharedSocioeconomicPathway end
struct SSP370 <: SharedSocioeconomicPathway end
struct SSP585 <: SharedSocioeconomicPathway end

"""
    Future{<:RasterDataSet,<:CMIPphase,<:ClimateModel,<:ClimateScenario}

Future climate datasets specified with a dataset, phase, model, and scenario.

## Type Parameters

#### `RasterDataSet`

Currently [`BioClim`](@ref) and [`Climate`](@ref) are implemented
for the [`CHELSA`](@ref) data source.

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
dataset = Future{BioClim, CMIP5, BNUESM, RCP45}
# output
Future{BioClim, CMIP5, BNUESM, RCP45}
```
Currently `Future` is only implented for `CHELSA`

```jldoctest future
datasource = CHELSA{Future{BioClim, CMIP5, BNUESM, RCP45}}
```

"""
struct Future{D<:RasterDataSet,C<:CMIPphase,M<:ClimateModel,S<:ClimateScenario} end

_dataset(::Type{<:Future{D}}) where D = D
_dataset(::Type{<:Future{BioClimPlus}}) = BioClim
_phase(::Type{<:Future{<:Any,P}}) where P = P
_phase(::Type{<:ClimateModel{P}}) where P = P

_model(::Type{<:Future{<:Any,<:Any,M}}) where M = M
_scenario(::Type{<:Future{<:Any,<:Any,<:Any,S}}) where S = S
layers(::Type{<:Future{BioClimPlus}}) = BIOCLIMPLUS_LAYERS_FUTURE

# fallback for _format
_format(::Type, RCP::Type{<:RepresentativeConcentrationPathway}) = lowercase(string(nameof(RCP)))
_format(::Type, S::Type{<:SharedSocioeconomicPathway}) = lowercase(string(nameof(S)))
_format(::Type, S::Type{<:ClimateModel}) = replace(string(nameof(S)), "_" => "-")

"""
    ModisProduct <: RasterDataSet

Abstract supertype for [`MODIS`](@ref)/VIIRS products. 

# Usage

Some commonly used products are `MOD13Q1` (250m resolution MODIS vegetation indices) and `VNP13A1` (500m resolution VIIRS vegetation indices). Refer to the [MODIS documentation](https://modis.ornl.gov/documentation.html) for detailed product information.
"""
abstract type ModisProduct <: RasterDataSet end

struct ECO4ESIPTJPL <: ModisProduct end
struct ECO4WUE <: ModisProduct end
struct GEDI03 <: ModisProduct end
struct GEDI04_B <: ModisProduct end
struct MCD12Q1 <: ModisProduct end
struct MCD12Q2 <: ModisProduct end
struct MCD15A2H <: ModisProduct end
struct MCD15A3H <: ModisProduct end
struct MCD19A3 <: ModisProduct end
struct MCD43A <: ModisProduct end
struct MCD43A1 <: ModisProduct end
struct MCD43A4 <: ModisProduct end
struct MCD64A1 <: ModisProduct end
struct MOD09A1 <: ModisProduct end
struct MOD11A2 <: ModisProduct end
struct MOD13Q1 <: ModisProduct end
struct MOD14A2 <: ModisProduct end
struct MOD15A2H <: ModisProduct end
struct MOD16A2 <: ModisProduct end
struct MOD17A2H <: ModisProduct end
struct MOD17A3HGF <: ModisProduct end
struct MOD21A2 <: ModisProduct end
struct MOD44B <: ModisProduct end
struct MYD09A1 <: ModisProduct end
struct MYD11A2 <: ModisProduct end
struct MYD13Q1 <: ModisProduct end
struct MYD14A2 <: ModisProduct end
struct MYD15A2H <: ModisProduct end
struct MYD16A2 <: ModisProduct end
struct MYD17A2H <: ModisProduct end
struct MYD17A3HGF <: ModisProduct end
struct MYD21A2 <: ModisProduct end
struct SIF005 <: ModisProduct end
struct SIF_ANN <: ModisProduct end
struct VNP09A1 <: ModisProduct end
struct VNP09H1 <: ModisProduct end
struct VNP13A1 <: ModisProduct end
struct VNP15A2H <: ModisProduct end
struct VNP21A2 <: ModisProduct end
struct VNP22Q2 <: ModisProduct end