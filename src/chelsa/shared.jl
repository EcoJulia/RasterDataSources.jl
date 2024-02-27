"""
    CHELSA{Union{BioClim,<:Future}} <: RasterDataSource

Data from CHELSA, currently implements the current `BioClim` and
`Future{BioClim}` variables, and `Future{Climate}`.

See: [chelsa-climate.org](https://chelsa-climate.org/) for the dataset,
and the [`getraster`](@ref) docs for implementation details.
"""
struct CHELSA{X} <: RasterDataSource end

rasterpath(::Type{CHELSA}) = joinpath(rasterpath(), "CHELSA")
rasterurl(::Type{CHELSA}, ::Val{2}) = URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V2/GLOBAL/")
rasterurl(::Type{CHELSA}, ::Val{1}) = URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V1/")

latest_patch(c::Type{<:CHELSA}, ::Val{1}) = 2
latest_patch(c::Type{<:CHELSA}, ::Val{2}) = 1

CHELSA_KEYWORDS = """
- `version`: `Integer` indicating the CHELSA version, currently either `1` or `2`.
- `patch`: `Integer` indicating the CHELSA patch number. Defaults to the latest patch (V1.2 and V2.1)
"""