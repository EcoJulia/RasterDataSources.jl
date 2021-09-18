using Documenter, RasterDataSources

makedocs(
    sitename = "RasterDataSources.jl",
    checkdocs = :all,
    strict = true,
)

deploydocs(
    repo = "github.com/EcoJulia/RasterDataSources.jl.git",
)
