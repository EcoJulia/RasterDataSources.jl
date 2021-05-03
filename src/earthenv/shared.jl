"""
    EarthEnv{Union{HabitatHeterogeneity,LandCover}} <: RasterDataSource

Data from the `EarthEnv` including `HabitatHeterogeneity` and `LandCover`

See: [www.earthenv.org](http://www.earthenv.org/)
"""
struct EarthEnv{X} <: RasterDataSource end

rasterpath(::Type{EarthEnv}) = joinpath(rasterpath(), "EarthEnv")

rasterurl(::Type{EarthEnv}) = URI(scheme="https", host="data.earthenv.org")
