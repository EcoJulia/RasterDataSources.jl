@testset "CHELSEA BioClim" begin
    using SimpleSDMDataSources: rasterurl

    @test rastername(CHELSA{BioClim}, 5) == "CHELSA_bio10_05.tif"

    bioclim_path = joinpath(ENV["ECODATASOURCES_PATH"], "CHELSA/BioClim")
    @test rasterpath(CHELSA{BioClim}) == bioclim_path
    @test rasterpath(CHELSA{BioClim}, 5) == joinpath(bioclim_path, "CHELSA_bio10_05.tif")

    @test rasterurl(CHELSA) == "ftp://envidatrepo.wsl.ch/uploads/chelsa/"
    @test rasterurl(CHELSA{BioClim}, 5) == "ftp://envidatrepo.wsl.ch/uploads/chelsa/chelsa_V1/climatologies/bio/CHELSA_bio10_05.tif"

    download_raster(CHELSA{BioClim}; layer=5)
    @test isfile(joinpath(bioclim_path, "CHELSA_bio10_05.tif"))
end
