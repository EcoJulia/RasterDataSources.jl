struct CRU{X} <: RasterDataSource end

const CRU_URI = URI(scheme="https", host="crudata.uea.ac.uk", path="/cru/data/hrg/tmc")

rasterpath(::Type{CRU}) = joinpath(rasterpath(), "CRU")

rasterpath(::Type{CRU{T}}) where T = joinpath(rasterpath(CRU), string(nameof(T)))
rasterpath(T::Type{<:CRU}, layer; kw...) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; kw...))