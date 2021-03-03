"""
    CHELSA{BioClim} <: RasterDataSource

Data from CHELSA, currently implements thet current and future bioclim
variables.

See: [chelsa-climate.org](https://chelsa-climate.org/)
"""
struct CHELSA{X} <: RasterDataSource end

rasterpath(::Type{CHELSA}) = joinpath(rasterpath(), "CHELSA")
rasterurl(::Type{CHELSA}) = URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V1/")

# Layer definitions
layers(::Type{CHELSA{BioClim}}) = 1:19

# Format future models and RCPs
_format(::Type{CHELSA}, ::Type{RCP26}) = "rcp26"
_format(::Type{CHELSA}, ::Type{RCP45}) = "rcp45"
_format(::Type{CHELSA}, ::Type{RCP60}) = "rcp60"
_format(::Type{CHELSA}, ::Type{RCP85}) = "rcp85"

_format(::Type{CHELSA}, ::Type{ACCESS1}) = "ACCESS1-0"
_format(::Type{CHELSA}, ::Type{BNUESM}) = "BNU-ESM"
_format(::Type{CHELSA}, ::Type{CCSM4}) = "CCSM4"
_format(::Type{CHELSA}, ::Type{CESM1BGC}) = "CESM1-BGC"
_format(::Type{CHELSA}, ::Type{CESM1CAM5}) = "CESM1-CAM5"
_format(::Type{CHELSA}, ::Type{CMCCCMS}) = "CMCC-CMS"
_format(::Type{CHELSA}, ::Type{CMCCCM}) = "CMCC-CM"
_format(::Type{CHELSA}, ::Type{CNRMCM5}) = "CNRM-CM5"
_format(::Type{CHELSA}, ::Type{CSIROMk3}) = "CSIRO-Mk3"
_format(::Type{CHELSA}, ::Type{CanESM2}) = "CanESM2"
_format(::Type{CHELSA}, ::Type{FGOALS}) = "FGOALS-g2"
_format(::Type{CHELSA}, ::Type{FIOESM}) = "FIO-ESM"
_format(::Type{CHELSA}, ::Type{GFDLCM3}) = "GFDL-CM3"
_format(::Type{CHELSA}, ::Type{GFDLESM2G}) = "GFDL-ESM2G"
_format(::Type{CHELSA}, ::Type{GFDLESM2M}) = "GFDL-ESM2M"
_format(::Type{CHELSA}, ::Type{GISSE2HCC}) = "GISS-E2-H-CC"
_format(::Type{CHELSA}, ::Type{GISSE2H}) = "GISS-E2-H"
_format(::Type{CHELSA}, ::Type{GISSE2RCC}) = "GISS-E2-R-CC"
_format(::Type{CHELSA}, ::Type{GISSE2R}) = "GISS-E2-R"
_format(::Type{CHELSA}, ::Type{HadGEM2AO}) = "HadGEM2-AO"
_format(::Type{CHELSA}, ::Type{HadGEM2CC}) = "HadGEM2-CC"
_format(::Type{CHELSA}, ::Type{IPSLCM5ALR}) = "IPSL-CM5A-LR"
_format(::Type{CHELSA}, ::Type{IPSLCM5AMR}) = "IPSL-CM5A-MR"
_format(::Type{CHELSA}, ::Type{MIROCESMCHEM}) = "MIROC-ESM-CHEM"
_format(::Type{CHELSA}, ::Type{MIROCESM}) = "MIROC-ESM"
_format(::Type{CHELSA}, ::Type{MIROC5}) = "MIROC5"
_format(::Type{CHELSA}, ::Type{MPIESMLR}) = "MPI-ESM-LR"
_format(::Type{CHELSA}, ::Type{MPIESMMR}) = "MPI-ESM-MR"
_format(::Type{CHELSA}, ::Type{MRICGCM3}) = "MRI-CGCM3"
_format(::Type{CHELSA}, ::Type{MRIESM1}) = "MRI-ESM1"
_format(::Type{CHELSA}, ::Type{NorESM1M}) = "NorESM1-M"
_format(::Type{CHELSA}, ::Type{BCCCSM1}) = "bcc-csm-1"
_format(::Type{CHELSA}, ::Type{Inmcm4}) = "inmcm4"