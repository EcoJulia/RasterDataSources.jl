function download_raster(T::Type{EarthEnv{LandCover}}; layer::Integer=1, discover::Bool=false)
    1 ≤ layer ≤ 12 || throw(ArgumentError("The layer must be between 1 and 12"))
    url = rasterurl(T, layer, discover)
    path = rasterpath(T, layer, discover)
    return _maybe_download(url, path)
end

function rastername(::Type{EarthEnv{LandCover}}, layer::Integer, discover::Bool) 
    filetype = discover ? "complete" : "partial"
    "landcover_$(filetype)_$(layer).tif"
end

rasterpath(T::Type{EarthEnv{LandCover}}, layer::Integer, discover::Bool) =
    joinpath(rasterpath(T), rastername(T, layer, discover))

function rasterurl(T::Type{EarthEnv{LandCover}}, layer::Integer, discover::Bool) 
    stem = discover ? "with_DISCover/consensus_full_class_$(layer).tif" :
                      "without_DISCover/Consensus_reduced_class_$(layer).tif"
    joinpath(rasterurl(T), stem)
end

_pathsegment(::Type{LandCover}) = "consensus_landcover"
