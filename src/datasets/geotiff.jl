function _find_span(n, m, M, pos)
    pos > M && return nothing
    pos < m && return nothing
    stride = (M - m) / n
    centers = (m + 0.5stride):stride:(M-0.5stride)
    span_pos = last(findmin(abs.(pos .- centers)))
    return (stride, centers[span_pos], span_pos)
end

"""
    geotiff(::Type{LT}, tiff_file; left::T=-180.0, right::T=180.0, bottom::T=-90.0, top::T=90.0) where {LT <: SimpleSDMLayer, T <: Number}

The geotiff function reads a geotiff file, and returns it as a matrix of the
correct type. The optional arguments `left`, `right`, `bottom`, and `left` are
defining the bounding box to read from the file. This is particularly useful if
you want to get a small subset from large files.

The first argument is the type of the `SimpleSDMLayer` to be returned.
"""
function geotiff(
    ::Type{LT},
    ::Type{ST},
    tiff_file;
    left = nothing,
    right = nothing,
    bottom = nothing,
    top = nothing,
) where {LT<:SimpleSDMLayer,ST<:SimpleSDMSource}

    left = isnothing(left) ? minimum(longitudes(ST)) : left
    right = isnothing(right) ? maximum(longitudes(ST)) : right
    bottom = isnothing(bottom) ? minimum(latitudes(ST)) : bottom
    top = isnothing(top) ? maximum(latitudes(ST)) : top

    # We do a bunch of checking that the required bounding box is not out of bounds
    # for the range of latitudes and longitudes.
    @assert right > left
    @assert top > bottom

    # This next block is reading the geotiff file, but also making sure that we
    # clip the file correctly to avoid reading more than we need.
    ArchGDAL.read(tiff_file) do dataset

        # The data we need is pretty much always going to be stored in the first
        # band, so this is what we will get for now. Note that this is not
        # reading the data yet, just retrieving the metadata.
        band = ArchGDAL.getband(dataset, 1)

        # This next bit of information is crucial, as it will allow us to assign
        # a matrix of the correct size, but also to get the right latitudes and
        # longitudes.
        width = ArchGDAL.width(dataset)
        height = ArchGDAL.height(dataset)

        global lon_stride, lat_stride
        global left_pos, right_pos
        global bottom_pos, top_pos

        lon_stride, left_pos, min_width = _find_span(width, minimum(longitudes(ST)), maximum(longitudes(ST)), left)
        _, right_pos, max_width = _find_span(width, minimum(longitudes(ST)), maximum(longitudes(ST)), right)

        lat_stride, top_pos, max_height = _find_span(height, minimum(latitudes(ST)), maximum(latitudes(ST)), top)
        _, bottom_pos, min_height = _find_span(height, minimum(latitudes(ST)), maximum(latitudes(ST)), bottom)

        max_height, min_height = height .- (min_height, max_height) .+ 1

        # We are now ready to initialize a matrix of the correct type.
        pixel_type = ArchGDAL.pixeltype(band)
        buffer = Matrix{pixel_type}(undef, length(min_width:max_width), length(min_height:max_height))
        ArchGDAL.read!(dataset, buffer, 1, min_height:max_height, min_width:max_width)
    end

    buffer = convert(Matrix{Union{Nothing,eltype(buffer)}}, rotl90(buffer))
    buffer[findall(buffer .== minimum(buffer))] .= nothing

    return LT(buffer, left_pos-0.5lon_stride, right_pos+0.5lon_stride, bottom_pos+0.5lat_stride, top_pos-0.5lat_stride)

end
