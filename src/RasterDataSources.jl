module RasterDataSources
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end RasterDataSources

using Dates,
      GeoData,
      HTTP,
      Requires,
      URIs,
      ZipFile

export WorldClim, CHELSA, EarthEnv, AWAP, ALWB

export BioClim, Climate, Weather, LandCover, HabitatHeterogeneity

# RCP
export RCP26, RCP45, RCP60, RCP85
export SSP126, SSP245, SSP370, SSP585

# CC models from CMIP5 (used in CHELSA)
export ACCESS1, BNUESM, CCSM4, CESM1BGC, CESM1CAM5, CMCCCMS, CMCCCM, CNRMCM5,
    CSIROMk3, CanESM2, FGOALS, FIOESM, GFDLCM3, GFDLESM2G, GFDLESM2M, GISSE2HCC,
    GISSE2H, GISSE2RCC, GISSE2R, HadGEM2AO, HadGEM2CC, IPSLCM5ALR, IPSLCM5AMR,
    MIROCESMCHEM, MIROCESM, MIROC5, MPIESMLR, MPIESMMR, MRICGCM3, MRIESM1, NorESM1M,
    BCCCSM1, Inmcm4

# CC models from CMIP6 (used in WorldClim)
export BCCCSM2MR, CNRMCM61, CNRMESM21, CanESM5, GFDLESM4, IPSLCM6ALR, MIROCES2L, MIROC6, MRIESM2

# Future datasets
export FutureClimate

export Values, Deciles

export getraster

export geoarray, stack, series

include("types/data.jl")
include("types/futures.jl")

include("shared.jl")

include("worldclim/shared.jl")
include("worldclim/bioclim.jl")
include("worldclim/climate.jl")
include("worldclim/weather.jl")

include("chelsa/shared.jl")
include("chelsa/bioclim.jl")
include("chelsa/futures.jl")

include("earthenv/shared.jl")
include("earthenv/landcover.jl")
include("earthenv/habitatheterogeneity.jl")

include("awap/awap.jl")

include("alwb/alwb.jl")

function __init__()
    @require GeoData="9b6fcbb8-86d6-11e9-1ce7-23a6bb139a78" begin
        include("geodata.jl")
    end
end

end # module
