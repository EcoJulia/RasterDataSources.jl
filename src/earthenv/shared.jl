
rasterpath(::Type{EarthEnv}) = joinpath(rasterpath(), "EarthEnv")
rasterpath(::Type{EarthEnv{X}}) where {X} = joinpath(rasterpath(EarthEnv), _pathsegment(X))

rasterurl(::Type{EarthEnv}) =  "https://data.earthenv.org"
rasterurl(::Type{EarthEnv{X}}) where {X} = joinpath(rasterurl(EarthEnv), _pathsegment(X))
