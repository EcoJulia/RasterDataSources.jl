function download_raster(::Type{CHELSA}, ::Type{BioClim}; layer::Integer=1)
    1 ≤ layer ≤ 19 || throw(ArgumentError("The layer must be between 1 and 19"))
    path = SimpleSDMDataSources._raster_assets_folder(CHELSA, BioClim)
    layer = lpad(layer, 2, "0")
    filename = "CHELSA_bio10_$(layer).tif"
    url_root = "ftp://envidatrepo.wsl.ch/uploads/chelsa/chelsa_V1/climatologies/bio/"

    filepath = joinpath(path, filename)
    return SimpleSDMDataSources._download_file(filepath, url_root * filename)
end
