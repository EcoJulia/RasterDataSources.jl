module RasterDataSources
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end RasterDataSources

using Dates,
      HTTP,
      URIs,
      ZipFile,
      JSON.Parser,
      ASCIIrasters,
      DelimitedFiles

export WorldClim, CHELSA, EarthEnv, AWAP, ALWB, SRTM, MODIS

export BioClim, Climate, Weather, LandCover, HabitatHeterogeneity

export Future, CMIP5, CMIP6

export RCP26, RCP45, RCP60, RCP85
export SSP126, SSP245, SSP370, SSP585

export ModisProduct

export ECO4ESIPTJPL,ECO4WUE,GEDI03,GEDI04_B,MCD12Q1,MCD12Q2,MCD15A2H,
    MCD15A3H,MCD19A3,MCD43A,MCD43A1,MCD43A4,MCD64A1,MOD09A1,MOD11A2,MOD13Q1,
    MOD14A2,MOD15A2H,MOD16A2,MOD17A2H,MOD17A3HGF,MOD21A2,MOD44B,MYD09A1,
    MYD11A2,MYD13Q1,MYD14A2,MYD15A2H,MYD16A2,MYD17A2H,MYD17A3HGF,MYD21A2,
    SIF005,SIF_ANN,VNP09A1,VNP09H1,VNP13A1,VNP15A2H,VNP21A2,VNP22Q2,
    ECO4ESIPTJPL, ECO4WUE, GEDI03, GEDI04_B, MCD12Q1, MCD12Q2, MCD15A2H, 
    MCD15A3H, MCD19A3, MCD43A, MCD43A1, MCD43A4, MCD64A1, MOD09A1, MOD11A2, 
    MOD13Q1, MOD14A2, MOD15A2H, MOD16A2, MOD17A2H, MOD17A3HGF, MOD21A2, 
    MOD44B, MYD09A1, MYD11A2, MYD13Q1, MYD14A2, MYD15A2H, MYD16A2, 
    MYD17A2H, MYD17A3HGF, MYD21A2, SIF005, SIF_ANN, VNP09A1, VNP09H1, 
    VNP13A1, VNP15A2H, VNP21A2, VNP22Q2

# Climate models from CMIP5 (used in CHELSA)
export ACCESS1, BNUESM, CCSM4, CESM1BGC, CESM1CAM5, CMCCCMS, CMCCCM, CNRMCM5,
    CSIROMk3, CanESM2, FGOALS, FIOESM, GFDLCM3, GFDLESM2G, GFDLESM2M, GISSE2HCC,
    GISSE2H, GISSE2RCC, GISSE2R, HadGEM2AO, HadGEM2CC, IPSLCM5ALR, IPSLCM5AMR,
    MIROCESMCHEM, MIROCESM, MIROC5, MPIESMLR, MPIESMMR, MRICGCM3, MRIESM1, NorESM1M,
    BCCCSM1, Inmcm4

# Climate models from CMIP6 (used in WorldClim)
export BCCCSM2MR, CNRMCM61, CNRMESM21, CanESM5, GFDLESM4, IPSLCM6ALR, MIROCES2L, MIROC6, MRIESM2


export Values, Deciles

export getraster

include("interface.jl")
include("types.jl")
include("shared.jl")

include("worldclim/shared.jl")
include("worldclim/bioclim.jl")
include("worldclim/climate.jl")
include("worldclim/weather.jl")

include("chelsa/shared.jl")
include("chelsa/bioclim.jl")
include("chelsa/future.jl")

include("earthenv/shared.jl")
include("earthenv/landcover.jl")
include("earthenv/habitatheterogeneity.jl")

include("awap/awap.jl")

include("alwb/alwb.jl")

include("srtm/srtm.jl")

include("modis/shared.jl")
include("modis/products.jl")
include("modis/utilities.jl")
include("modis/examples.jl")

end # module
