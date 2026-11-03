using Documenter, RasterDataSources, Changelog

Changelog.generate(
    Changelog.Documenter(),
    joinpath(@__DIR__, "..", "CHANGELOG.md"),
    joinpath(@__DIR__, "src", "changelog.md");
    repo = "EcoJulia/RasterDataSources.jl",
)

makedocs(
    sitename = "RasterDataSources.jl",
    checkdocs = :all,
    pages = ["index.md", "changelog.md"],
)

deploydocs(
    repo = "github.com/EcoJulia/RasterDataSources.jl.git",
)
