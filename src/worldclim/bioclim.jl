function download_raster(::Type{WorldClim}, ::Type{BioClim}; layer::Integer=1, resolution::AbstractFloat=10.0)

    1 ≤ layer ≤ 19 || throw(ArgumentError("The layer must be between 1 and 19"))

    # Path to save the data
    path = SimpleSDMDataSources._raster_assets_folder(WorldClim, BioClim)

    resolutions = Dict(2.5 => "2.5", 5.0 => "5", 10.0 => "10")

    output_file = joinpath(path, "wc2.1_$(resolutions[resolution])m_bio_$(layer).tif")
    zip_file = joinpath(path, "bioclim_2.1_$(resolutions[resolution])m.zip")

    if !isfile(path)
        if !isfile(zip_file)
            root = "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/"
            stem = "wc2.1_$(resolutions[resolution])m_bio.zip"
            r = HTTP.request("GET", root * stem)
            open(zip_file, "w") do f
                write(f, String(r.body))
            end
        end
        zf = ZipFile.Reader(zip_file)
        file_to_read =
            first(filter(f -> joinpath(path, f.name) == output_file, zf.files))

        if !isfile(joinpath(path, file_to_read.name))
            write(joinpath(path, file_to_read.name), read(file_to_read))
        end
        close(zf)
    end

    return joinpath(path, file_to_read.name)
end

