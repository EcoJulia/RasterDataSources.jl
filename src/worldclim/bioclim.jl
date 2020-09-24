struct BioClim <: SDMDataSet end

const resolutions = Dict(2.5 => "2.5", 5.0 => "5", 10.0 => "10")

function download_raster(T::Type{WorldClim{BioClim}}; layer::Integer=1, resolution::AbstractFloat=10.0)
    1 ≤ layer ≤ 19 || throw(ArgumentError("The layer must be between 1 and 19"))

    raster_path = rasterpath(T, layer, resolution)
    zip_path = zippath(T, layer, resolution)

    if !isfile(raster_path)
        _maybe_download(zipurl(T, layer, resolution), zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, layer, resolution)
        zf = ZipFile.Reader(zip_path)
        write(raster_path, read(file_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

# BioClim layers don't get their own folder
rasterpath(T::Type{<:WorldClim{BioClim}}, layer) = rasterpath(T)

rastername(T::Type{<:WorldClim{BioClim}}, key, res::AbstractFloat) =
    "wc2.1_$(resolutions[res])m_bio_$(key).tif"

zipname(T::Type{<:WorldClim{BioClim}}, key, res::AbstractFloat) =
    "wc2.1_$(resolutions[res])m_bio.zip"

zipurl(T::Type{<:WorldClim{BioClim}}, key, res::AbstractFloat) =
    joinpath(WORLDCLIM_URL, "base", zipname(T, key, res))

zippath(T::Type{<:WorldClim{BioClim}}, key, res::AbstractFloat) =
    joinpath(rasterpath(T), "zips", zipname(T, key, res))
