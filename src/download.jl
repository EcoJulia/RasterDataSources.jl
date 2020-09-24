function _maybe_download(url, filepath)
    if !isfile(filepath)
        mkpath(dirname(filepath))
        HTTP.download(url, filepath)
    end
    filepath
end
