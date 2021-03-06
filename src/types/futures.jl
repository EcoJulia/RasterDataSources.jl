
"""
    FutureRaster

Asbtract type for any "future" element - anything that represents a temporal
projection will be represented by a subtype of this.
"""
abstract type FutureRaster end

"""
    ClimateModel

Abstract type for climate models.
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


"""
    RepresentativeConcentrationPathway

Abstract type for Representative Concentration Pathways (RCPs)
"""
abstract type RepresentativeConcentrationPathway end

struct RCP26 <: RepresentativeConcentrationPathway end
struct RCP45 <: RepresentativeConcentrationPathway end
struct RCP60 <: RepresentativeConcentrationPathway end
struct RCP85 <: RepresentativeConcentrationPathway end

"""
    SharedSocioeconomicPathway

Abstract type for Shared Socio-economic Pathways (SSPs)
"""
abstract type SharedSocioeconomicPathway end

struct SSP126 <: SharedSocioeconomicPathway end
struct SSP245 <: SharedSocioeconomicPathway end
struct SSP370 <: SharedSocioeconomicPathway end
struct SSP585 <: SharedSocioeconomicPathway end

"""
    ClimateScenario

A ClimateScenario can be a RCP or a SSP
"""
ClimateScenario = Union{RepresentativeConcentrationPathway, SharedSocioeconomicPathway}

"""
    FutureClimate{M<:ClimateModel, S<:ClimateScenario} <: FutureRaster

Future climate dataset: specified by a model and a scenario
"""
struct FutureClimate{M<:ClimateModel, S<:ClimateScenario} <: FutureRaster end
_model(::Type{FutureClimate{X,Y}}) where {X,Y} = X
_scenario(::Type{FutureClimate{X,Y}}) where {X,Y} = Y