"""
    CHELSA{Union{BioClim,<:Future}} <: RasterDataSource

Data from CHELSA, currently implements the current `BioClim` and
`Future{BioClim}` variables, and `Future{Climate}`.

See: [chelsa-climate.org](https://chelsa-climate.org/) for the dataset,
and the [`getraster`](@ref) docs for implementation details.
"""
struct CHELSA{X} <: RasterDataSource end

rasterpath(::Type{CHELSA}) = joinpath(rasterpath(), "CHELSA")
function rasterurl(T::Type{CHELSA}, version)
    if version == 1
        joinpath(rasterurl(T), "chelsa_V1")
    elseif version == 2
        joinpath(rasterurl(T), "chelsa_V2/GLOBAL")
    else 
        CHELSA_invalid_version(version)
    end
end
rasterurl(::Type{CHELSA}) = URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/")

function latest_patch(::Type{<:CHELSA}, v)
    if v == 1
        2
    elseif v == 2
        1
    else
        CHELSA_invalid_version(v)
    end
end

const CHELSA_KEYWORDS = """
- `version`: `Integer` indicating the CHELSA version, currently either `1` or `2`.
- `patch`: `Integer` indicating the CHELSA patch number. Defaults to the latest patch (V1.2 and V2.1)
"""

CHELSA_invalid_version(v, valid_versions = [1,2]) = 
        throw(ArgumentError("Version $v is not available for CHELSA. Available versions: $valid_versions."))

function CHELSA_warn_version(T, layer, version, patch, path)
    if version == 2 && !isfile(path) && isfile(rasterpath(T, layer, 1, 2))
        @info "File for CHELSA v1.2 detected, but requested version is CHELSA v$version.$patch. 
To load data for CHELSA v1.2 instead, set version keyword to 1"
    end
end