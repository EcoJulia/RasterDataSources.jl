function _maybe_download(uri::URI, filepath)
    if !isfile(filepath)
        mkpath(dirname(filepath))
        println("Starting download for $uri")
        HTTP.download(string(uri), filepath)
    end
    filepath
end

_check_resolution(T, res) =
    res in resolutions(T) || throw(ArgumentError("Resolution $res not in $(resolutions(T))"))
_check_layer(T, layer) = 
    layer in layers(T) || throw(ArgumentError("Layer $layer not in $(layers(T))"))
