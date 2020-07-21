function raster(::Type{IT}, source::ST; layer::Integer=1, left=nothing, right=nothing, bottom=nothing, top=nothing) where {IT <: SimpleSDMLayer, ST <: SimpleSDMSource}
    file = download_layer(source, layer)
    left = isnothing(left) ? minimum(longitudes(ST)) : left
    right = isnothing(right) ? maximum(longitudes(ST)) : right
    bottom = isnothing(bottom) ? minimum(latitudes(ST)) : bottom
    top = isnothing(top) ? maximum(latitudes(ST)) : top
    return geotiff(IT, ST, file; left=left, right=right, bottom=bottom, top=top)
end

function raster(::Type{IT}, source::ST, file; left=nothing, right=nothing, bottom=nothing, top=nothing) where {IT <: SimpleSDMLayer, ST <: SimpleSDMSource}
    left = isnothing(left) ? minimum(longitudes(ST)) : left
    right = isnothing(right) ? maximum(longitudes(ST)) : right
    bottom = isnothing(bottom) ? minimum(latitudes(ST)) : bottom
    top = isnothing(top) ? maximum(latitudes(ST)) : top
    return geotiff(IT, ST, file; left=left, right=right, bottom=bottom, top=top)
end
