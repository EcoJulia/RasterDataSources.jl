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
    ClimateModel

Abstract supertype for climate models use in [`Future`](@ref) datasets.
"""
abstract type ClimateModel end

struct ACCESS1 <: ClimateModel end
struct BNUESM <: ClimateModel end
struct CCSM4 <: ClimateModel end
struct CESM1BGC <: ClimateModel end
struct CESM1CAM5 <: ClimateModel end
struct CMCCCMS <: ClimateModel end
struct CMCCCM <: ClimateModel end
struct CNRMCM5 <: ClimateModel end
struct CSIROMk3 <: ClimateModel end
struct CanESM2 <: ClimateModel end
struct FGOALS <: ClimateModel end
struct FIOESM <: ClimateModel end
struct GFDLCM3 <: ClimateModel end
struct GFDLESM2G <: ClimateModel end
struct GFDLESM2M <: ClimateModel end
struct GISSE2HCC <: ClimateModel end
struct GISSE2H <: ClimateModel end
struct GISSE2RCC <: ClimateModel end
struct GISSE2R <: ClimateModel end
struct HadGEM2AO <: ClimateModel end
struct HadGEM2CC <: ClimateModel end
struct IPSLCM5ALR <: ClimateModel end
struct IPSLCM5AMR <: ClimateModel end
struct MIROCESMCHEM <: ClimateModel end
struct MIROCESM <: ClimateModel end
struct MIROC5 <: ClimateModel end
struct MPIESMLR <: ClimateModel end
struct MPIESMMR <: ClimateModel end
struct MRICGCM3 <: ClimateModel end
struct MRIESM1 <: ClimateModel end
struct NorESM1M <: ClimateModel end
struct BCCCSM1 <: ClimateModel end
struct Inmcm4 <: ClimateModel end
struct BCCCSM2MR <: ClimateModel end
struct CNRMCM61 <: ClimateModel end
struct CNRMESM21 <: ClimateModel end
struct CanESM5 <: ClimateModel end
struct GFDLESM4 <: ClimateModel end
struct IPSLCM6ALR <: ClimateModel end
struct MIROCES2L <: ClimateModel end
struct MIROC6 <: ClimateModel end
struct MRIESM2 <: ClimateModel end
struct UKESM <: ClimateModel end
struct MPIESMHR <: ClimateModel end

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

`ACCESS1`, `BNUESM`, `CCSM4`, `CESM1BGC`, `CESM1CAM5`, `CMCCCMS`, `CMCCCM`,
`CNRMCM5`, `CSIROMk3`, `CanESM2`, `FGOALS`, `FIOESM`, `GFDLCM3`, `GFDLESM2G`,
`GFDLESM2M`, `GISSE2HCC`, `GISSE2H`, `GISSE2RCC`, `GISSE2R`, `HadGEM2AO`,
`HadGEM2CC`, `IPSLCM5ALR`, `IPSLCM5AMR`, `MIROCESMCHEM`, `MIROCESM`, `MIROC5`,
`MPIESMLR`, `MPIESMMR`, `MRICGCM3`, `MRIESM1`, `NorESM1M`, `BCCCSM1`, `Inmcm4`,
`BCCCSM2MR`, `CNRMCM61`, `CNRMESM21`, `CanESM5`, `MIROCES2L`, `MIROC6` for CMIP5;

`UKESM`, `MPIESMHR` `IPSLCM6ALR` `MRIESM2`, `GFDLESM4` for `CMIP6`.

#### `ClimateScenario`

CMIP5 Climate scenarios are all [`RepresentativeConcentrationPathway`](@ref)
and can be chosen from: `RCP26`, `RCP45`, `RCP60`, `RCP85`

CMIP6 Climate scenarios are all [`SharedSocioeconomicPathway`](@ref) and
can be chosen from: `SSP126`, `SSP245`, SSP370`, SSP585`

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
_phase(::Type{<:Future{<:Any,P}}) where P = P
_model(::Type{<:Future{<:Any,<:Any,M}}) where M = M
_scenario(::Type{<:Future{<:Any,<:Any,<:Any,S}}) where S = S


"""
    Abstract supertype for MODIS/VIIRS products
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