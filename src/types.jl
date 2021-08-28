"""
    RasterDataSource 

Abstract supertype for raster data collections.  
"""
abstract type RasterDataSource end

"""
    RasterDataSet

Abstract supertye for datasets that belong to a [`RasterDataSource`](@ref).
"""
abstract type RasterDataSet end

"""
    BioClim <: RasterDataSet

BioClim datasets. Usually containing layers from 1:19. They do not usually use
`month` or `date` keywords, but may use `date` in past/future scenarios. 
"""
struct BioClim <: RasterDataSet end

"""
    Climate <: RasterDataSet

Climate datasets. These are usually months of the year, not specific dates,
and use a `month` keyword in `getraster`. They may also use `date` in past/future scenarios.
"""
struct Climate <: RasterDataSet end

"""
    Weather <: RasterDataSet

Weather datasets. These are usually large time-series of specific dates,
and use a `date` keyword in `getraster`.
"""
struct Weather <: RasterDataSet end

"""
    LandCover <: RasterDataSet

Land-cover datasets.
"""
struct LandCover{X} <: RasterDataSet end

"""
    HabitatHeterogeneity <: RasterDataSet

Habitat heterogeneity datasets.
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
    RepresentativeConcentrationPathway

Abstract supertype for Representative Concentration Pathways (RCPs)
"""
abstract type RepresentativeConcentrationPathway end

struct RCP26 <: RepresentativeConcentrationPathway end
struct RCP45 <: RepresentativeConcentrationPathway end
struct RCP60 <: RepresentativeConcentrationPathway end
struct RCP85 <: RepresentativeConcentrationPathway end

"""
    SharedSocioeconomicPathway

Abstract supertype for Shared Socio-economic Pathways (SSPs)
"""
abstract type SharedSocioeconomicPathway end

struct SSP126 <: SharedSocioeconomicPathway end
struct SSP245 <: SharedSocioeconomicPathway end
struct SSP370 <: SharedSocioeconomicPathway end
struct SSP585 <: SharedSocioeconomicPathway end

# A ClimateScenario can be a RCP or a SSP
const ClimateScenario = Union{RepresentativeConcentrationPathway, SharedSocioeconomicPathway}

"""
    Future{D<:RasterDataSet,M<:ClimateModel,S<:ClimateScenario}

Future climate dataset: specified by a dataset, model, and scenario.
"""
struct Future{D<:RasterDataSet,C<:CMIPphase,M<:ClimateModel,S<:ClimateScenario} end

_dataset(::Type{<:Future{D}}) where D = D
_phase(::Type{<:Future{<:Any,P}}) where P = P
_model(::Type{<:Future{<:Any,<:Any,M}}) where M = M
_scenario(::Type{<:Future{<:Any,<:Any,<:Any,S}}) where S = S
