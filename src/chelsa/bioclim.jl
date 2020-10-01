# Interface methods

function download_raster(T::Type{CHELSA{BioClim}}; layer::Integer=1)
    1 ≤ layer ≤ 19 || throw(ArgumentError("The layer must be between 1 and 19"))
    path = rasterpath(T, layer)
    url = rasterurl(T, layer)
    return _maybe_download(url, path)
end

rastername(::Type{CHELSA{BioClim}}, layer) = "CHELSA_bio10_$(lpad(layer, 2, "0")).tif"

rasterpath(::Type{CHELSA}) = joinpath(rasterpath(), "CHELSA")
rasterpath(::Type{CHELSA{BioClim}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClim}}, layer) = joinpath(rasterpath(T), rastername(T, layer))

rasterurl(::Type{CHELSA}) = "ftp://envidatrepo.wsl.ch/uploads/chelsa/"
rasterurl(::Type{CHELSA{BioClim}}) = joinpath(rasterurl(CHELSA), "chelsa_V1/climatologies/bio/")
rasterurl(T::Type{CHELSA{BioClim}}, layer) = joinpath(rasterurl(T), rastername(T, layer))
