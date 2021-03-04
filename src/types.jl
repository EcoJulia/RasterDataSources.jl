"""
    RasterDataSource Abstract supertype for raster data collections.  """
abstract type RasterDataSource end

"""
    RasterDataSet

Abstract supertye for datasets that belong to a in a [`RasterDataSource`](@ref).
"""
abstract type RasterDataSet end

"""
    BioClim <: RasterDataSet

BioClim datasets. Usually containing 19 numbered layers.
"""
struct BioClim <: RasterDataSet end

"""
    Climate <: RasterDataSet

Climate datasets. These are usually months of the year, not specific dates.
"""
struct Climate <: RasterDataSet end

"""
    Weather <: RasterDataSet

Weather datasets. These are usually large time-series of specific dates.
"""
struct Weather <: RasterDataSet end

"""
    LandCover <: RasterDataSet

Land-cover datasets.
"""
struct LandCover <: RasterDataSet end

"""
    HabitatHeterogeneity <: RasterDataSet

Habitat heterogeneity datasets.
"""
struct HabitatHeterogeneity <: RasterDataSet end


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

abstract type RCP end
struct RCP26 <: RCP end
struct RCP45 <: RCP end
struct RCP60 <: RCP end
struct RCP85 <: RCP end

"""
Future version of a dataset
"""
struct Future{T<:Union{BioClim}, M<:ClimateModel, R<:RCP} <: RasterDataSet end