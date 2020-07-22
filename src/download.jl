function _download_file(filename, url)
    if !isfile(filename)
        layerrequest = HTTP.request("GET", url)
        open(filename, "w") do layerfile
            write(layerfile, String(layerrequest.body))
        end
    end
    return filename
end
