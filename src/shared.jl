
function getraster(T::Type{<:RasterDataSource}, layers=layers(T), args...; kw...)
    map(layers) do l
        _check_layer(T, l)
        getraster(T, l, args...; kw...)
    end
end

function _maybe_download(uri::URI, filepath; kw...)
    if !isfile(filepath)
        mkpath(dirname(filepath))
        println("Starting download for $uri")
        HTTP.download(string(uri), filepath; kw...)
    end
    filepath
end

function rasterpath() 
    if haskey(ENV, "RASTERDATASOURCES_PATH") && isdir(ENV["RASTERDATASOURCES_PATH"])
        ENV["RASTERDATASOURCES_PATH"]
    else
        error("You must set `ENV[\"RASTERDATASOURCES_PATH\"]` to a path in your system")
    end
end

function delete_rasters()
    # May need an "are you sure"? - this could be a lot of GB of data to lose
    ispath(rasterpath()) && rm(rasterpath())
end

function delete_rasters(T::Type)
    ispath(rasterpath(T)) && rm(rasterpath(T))
end

_check_res(T, res) =
    res in resolutions(T) || throw(ArgumentError("Resolution $res not in $(resolutions(T))"))
_check_layer(T, layer) =
    layer in layers(T) || throw(ArgumentError("Layer $layer not in $(layers(T))"))

_date2string(t, date) = Dates.format(date, _dateformat(t))
_string2date(t, d::AbstractString) = Date(d, _dateformat(t))

_date_sequence(dates::AbstractArray, step) = dates
_date_sequence(dates::NTuple{2}, step) = first(dates):step:last(dates)
_date_sequence(date, step) = date:step:date

