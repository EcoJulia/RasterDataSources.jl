using Documenter, RasterDataSources

makedocs(
    sitename = "RasterDataSources.jl",
    checkdocs = :all,
)

deploydocs(
    repo = "github.com/EcoJulia/RasterDataSources.jl.git",
)
