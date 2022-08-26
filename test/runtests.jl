using SafeTestsets, Aqua, RasterDataSources, Pkg

# as long as ASCIIrasters is not registered we have to
# install it manually from ./dev
Pkg.develop(path="../dev/ASCIIrasters")

if VERSION >= v"1.5.0"
    # HTTP.jl `write` is full of ambiguities
    # Aqua.test_ambiguities([RasterDataSources, Base, Core])
    Aqua.test_unbound_args(RasterDataSources)
    Aqua.test_stale_deps(RasterDataSources)
    Aqua.test_undefined_exports(RasterDataSources)
    Aqua.test_project_extras(RasterDataSources)
    Aqua.test_deps_compat(RasterDataSources)
    Aqua.test_project_toml_formatting(RasterDataSources)
end

@time @safetestset "alwb" begin include("alwb.jl") end
@time @safetestset "awap" begin include("awap.jl") end
@time @safetestset "chelsa bioclim" begin include("chelsa-bioclim.jl") end
@time @safetestset "chelsa future" begin include("chelsa-future.jl") end
@time @safetestset "earthenv habitat heterogeneity" begin include("earthenv-heterogeneity.jl") end
@time @safetestset "earthenv landcover" begin include("earthenv-landcover.jl") end
@time @safetestset "worldclim bioclim" begin include("worldclim-bioclim.jl") end
@time @safetestset "worldclim climate" begin include("worldclim-climate.jl") end
@time @safetestset "worldclim weather" begin include("worldclim-weather.jl") end
@time @safetestset "srtm" begin include("srtm.jl") end
@time @safetestset "modis utilities" begin include("modis-utilities.jl") end
@time @safetestset "modis product info" begin include("modis-products.jl") end
@time @safetestset "modis interface" begin include("modis-interface.jl") end
