"""
    CHELSA{BioClim} <: RasterDataSource

Data from CHELSA, currently implements thet current and future bioclim
variables.

See: [chelsa-climate.org](https://chelsa-climate.org/)
"""
struct CHELSA{X} <: RasterDataSource end

rasterpath(::Type{CHELSA}) = joinpath(rasterpath(), "CHELSA")
rasterurl(::Type{CHELSA}) = URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/")
