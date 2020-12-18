"""
CHELSA{BioClim} <: RasterDataSource

Data from CHELSA, currently only the `BioClim` layer is implemented.

See: [chelsa-climate.org](https://chelsa-climate.org/)
"""
struct CHELSA{X} <: RasterDataSource end

layers(::Type{CHELSA{BioClim}}) = 1:19

"""
    getraster(T::Type{CHELSA{BioClim}}, [layer::Integer]) => String

Download CHELSA BioClim data, choosing layers from: $(layers(CHELSA{BioClim})).

Without a layer argument, all layers will be getrastered, and a tuple of paths is returned. 
If the data is already getrastered the path will be returned.
"""
function getraster(T::Type{CHELSA{BioClim}}, layer::Integer)
    _check_layer(T, layer)
    path = rasterpath(T, layer)
    url = rasterurl(T, layer)
    return _maybe_download(url, path)
end

rastername(::Type{CHELSA{BioClim}}, layer::Integer) = "CHELSA_bio10_$(lpad(layer, 2, "0")).tif"

rasterpath(::Type{CHELSA}) = joinpath(rasterpath(), "CHELSA")
rasterpath(::Type{CHELSA{BioClim}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterpath(T), rastername(T, layer))

# https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V1/climatologies/bio/CHELSA_prec_01_V1.2_land.tif
rasterurl(::Type{CHELSA}) = URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V1/")
rasterurl(::Type{CHELSA{BioClim}}) = joinpath(rasterurl(CHELSA), "climatologies/bio/")
rasterurl(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterurl(T), rastername(T, layer))
