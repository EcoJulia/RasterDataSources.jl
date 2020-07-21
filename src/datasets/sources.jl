abstract type SimpleSDMSource end

latitudes(::Type{T}) where {T <: SimpleSDMSource} = (-90.0, 90.0)
longitudes(::Type{T}) where {T <: SimpleSDMSource} = (-180.0, 180.0)

struct WorldClim <: SimpleSDMSource
    resolution::AbstractFloat
    function WorldClim(resolution::AbstractFloat)
        resolution ∈ [2.5, 5.0, 10.0] || throw(ArgumentError("The resolution argument ($(resolution)) must be 2.5, 5, or 10"))
        return new(resolution)
    end
end

WorldClim() = WorldClim(10.0)

struct BioClim <: SimpleSDMSource end
longitudes(::Type{BioClim}) = (-180.0001388888, 179.9998611111)
latitudes(::Type{BioClim}) = (-90.0001388888, 83.9998611111)

struct EarthEnv <: SimpleSDMSource
    full::Bool
end

EarthEnv() = EarthEnv(false)
latitudes(::Type{EarthEnv}) = (-56.0, 90.0)
longitudes(::Type{EarthEnv}) = (-180.0, 180.0)
