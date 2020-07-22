function download_raster(::Type{EarthEnv}, ::Type{LandCover}; layer::Integer=1, discover::Bool=false)
    1 ≤ layer ≤ 12 || throw(ArgumentError("The layer must be between 1 and 12"))

    path = _raster_assets_folder(EarthEnv, LandCover)

    root = "https://data.earthenv.org/consensus_landcover/"
    stem = discover ? "with_DISCover/consensus_full_class_$(layer).tif" :
        "without_DISCover/Consensus_reduced_class_$(layer).tif"
    filetype = discover ? "complete" : "partial"
    filename = "landcover_$(filetype)_$(layer).tif"

    return _download_file(joinpath(path, filename), root * stem)

end
