using Documenter, RasterDataSources

makedocs(
    sitename = "RasterDataSources.jl",
    checkdocs = :all,
    strict = true,
)

deploydocs(
    repo = "github.com/cesaraustralia/RasterDataSources.jl.git",
)
