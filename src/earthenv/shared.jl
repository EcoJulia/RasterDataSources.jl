struct EarthEnv{X} <: RasterDataSource end

rasterpath(::Type{EarthEnv}) = joinpath(rasterpath(), "EarthEnv")

rasterurl(::Type{EarthEnv}) = URI(scheme="https", host="data.earthenv.org")
