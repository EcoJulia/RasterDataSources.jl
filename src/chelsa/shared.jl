"""
    CHELSA{Union{BioClim,<:Future}} <: RasterDataSource

Data from CHELSA, currently implements the current `BioClim` and
`Future{BioClim}` variables, and `Future{Climate}`.

See: [chelsa-climate.org](https://chelsa-climate.org/) for the dataset,
and the [`getraster`](@ref) docs for implementation details.
"""
struct CHELSA{X} <: RasterDataSource end

rasterpath(::Type{CHELSA}) = joinpath(rasterpath(), "CHELSA")
rasterurl(::Type{CHELSA}) = URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/")
