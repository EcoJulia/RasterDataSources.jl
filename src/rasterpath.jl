# Allow this to be set manually
function rasterpath() 
    if haskey(ENV, "RASTERDATASOURCES_PATH") && isdir(ENV["RASTERDATASOURCES_PATH"])
        ENV["RASTERDATASOURCES_PATH"]
    else
        error("You must set `ENV[\"RASTERDATASOURCES_PATH\"]` to a path in your system")
    end
end

function remove_rasters()
    # May need an "are you sure"? - this could be a lot of GB of data to lose
    ispath(rasterpath()) && rm(rasterpath())
end

function remove_rasters(T::Type)
    ispath(rasterpath(T)) && rm(rasterpath(T))
end

function remove_rasters(::Type{TS}, ::Type{TD}) where {TS <: RasterDataSource, TD <: RasterDataSet}
    ispath(_raster_assets_folder(TS, TD)) && rm(_raster_assets_folder(TS, TD); recursive=false)
end
