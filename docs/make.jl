using Documenter, RasterDataSources

makedocs(
    sitename = "RasterDataSources.jl",
    checkdocs = :all,
    pages = ["index.md", "era5.md"],
)

deploydocs(
    repo = "github.com/EcoJulia/RasterDataSources.jl.git",
)
