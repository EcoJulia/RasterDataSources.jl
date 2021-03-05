
"""
Asbtract type for any `Future` element - anything that represents a temporal
projection will be represented by a subtype of this.
"""
abstract type FutureRaster end

"""
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
struct BccCsm1 <: ClimateModel end
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
Abstract type for Representative Concentration Pathways (RCPs)
"""
abstract type RCP end

struct RCP26 <: RCP end
struct RCP45 <: RCP end
struct RCP60 <: RCP end
struct RCP85 <: RCP end

"""
Abstract type for Shared Socio-economic Pathways (SSPs)
"""
abstract type SSP end

struct SSP126 <: SSP end
struct SSP245 <: SSP end
struct SSP370 <: SSP end
struct SSP585 <: SSP end

"""
A ClimateScenario can be a RCP or a SSP
"""
ClimateScenario = Union{SSP, RCP}

"""
Future climate dataset: specified by a model and a scenario
"""
struct FutureClimate{C<:ClimateModel, R<:ClimateScenario} <: FutureRaster end
_model(::Type{FutureClimate{X,Y}}) where {X,Y} = X
_scenario(::Type{FutureClimate{X,Y}}) where {X,Y} = Y
_rcp(X) = _scenario(X)