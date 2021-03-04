
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

"""
Abstract type for RCPs
"""
abstract type RCP end

struct RCP26 <: RCP end
struct RCP45 <: RCP end
struct RCP60 <: RCP end
struct RCP85 <: RCP end


"""
Future climate dataset: specified by a model and a RCP
"""
struct FutureClimate{C<:ClimateModel, R<:RCP} <: FutureRaster end
_model(F::Type{FutureClimate{X,Y}}) where {X,Y} = X
_rcp(F::Type{FutureClimate{X,Y}}) where {X,Y} = Y