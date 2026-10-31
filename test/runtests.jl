using SafeTestsets, Aqua, RasterDataSources, Pkg, Dates, Test

@testset "Aqua" begin
    # HTTP.jl `write` is full of ambiguities
    # Aqua.test_ambiguities([RasterDataSources, Base, Core])
    Aqua.test_unbound_args(RasterDataSources)
    Aqua.test_stale_deps(RasterDataSources)
    Aqua.test_undefined_exports(RasterDataSources)
    Aqua.test_project_extras(RasterDataSources)
    Aqua.test_deps_compat(RasterDataSources; ignore=[:Dates, :DelimitedFiles, :CRC32c])
end

# ALWB and AWAP download URLs return 403 Forbidden — BOM's Akamai layer
# blocks them. Re-enable when the endpoints work again.
@time @safetestset "era5" begin include("era5.jl") end
@time @safetestset "era5 cds" begin include("era5-cds.jl") end
@time @safetestset "era5 arco" begin include("era5-arco.jl") end
@time @safetestset "terraclimate" begin include("terraclimate.jl") end
@time @safetestset "gridmet" begin include("gridmet.jl") end
@time @safetestset "silo" begin include("silo.jl") end
@time @safetestset "barra" begin include("barra.jl") end
@time @safetestset "chelsa bioclim" begin include("chelsa-bioclim.jl") end
@time @safetestset "chelsa climate" begin include("chelsa-climate.jl") end
@time @safetestset "chelsa future" begin include("chelsa-future.jl") end
@time @safetestset "earthenv habitat heterogeneity" begin include("earthenv-heterogeneity.jl") end
@time @safetestset "earthenv landcover" begin include("earthenv-landcover.jl") end
@time @safetestset "worldclim bioclim" begin include("worldclim-bioclim.jl") end
@time @safetestset "worldclim climate" begin include("worldclim-climate.jl") end
@time @safetestset "worldclim weather" begin include("worldclim-weather.jl") end
@time @safetestset "worldclim elevation" begin include("worldclim-elevation.jl") end
@time @safetestset "srtm" begin include("srtm.jl") end
@time @safetestset "copernicus dem" begin include("copernicus.jl") end
@time @safetestset "modis utilities" begin include("modis-utilities.jl") end
@time @safetestset "modis product info" begin include("modis-products.jl") end
@time @safetestset "modis extent" begin include("modis-extent.jl") end
@time @safetestset "modis interface" begin include("modis-interface.jl") end
@time @safetestset "ncep" begin include("ncep.jl") end
@time @safetestset "slga" begin include("slga.jl") end
@time @safetestset "gads" begin include("gads.jl") end
@time @safetestset "crucl2" begin include("crucl2.jl") end
@time @safetestset "cpcsoil" begin include("cpcsoil.jl") end
