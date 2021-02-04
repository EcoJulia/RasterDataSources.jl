const GD = GeoData

const LayerItr = Union{AbstractArray,Tuple}

"""
    geoarray(T::Type{<:RasterDataSource}, args...; kw...) => AbstractArray

Load a `RasterDataSource` as an `AbstractGeoStack`. `T`, `args` are
are passed to `getraster`, while `kw` args are for both `getraster` and
`AbstractGeoStack`.
"""
function geoarray end
"""
    stack(T::Type{<:RasterDataSource}, [layers::Union{Symbol,AbstractArray,Tuple}]; kw...) => AbstractGeoStack

Load a `RasterDataSource` as an `AbstractGeoStack`. `T`, `args` are
are passed to `getraster`, while `kw` args are for both `getraster` and
`AbstractGeoStack`.
"""
function stack end
stack(T, layer::Symbol; kw...) = stack(T, (layer,); kw...) 

"""
    series(T::Type{<:RasterDataSource}, [layers::Union{Symbol,AbstractArray,Tuple}]; kw...) => AbstractGeoSeries

Load a `RasterDataSource` as an `AbstractGeoSeries`. `T`, `args` are
are passed to `getraster`, while `kw` args are for both `getraster` and
`AbstractGeoSeries`.
"""
function series end
series(T, layer::Symbol; kw...) = series(T, (layer,); kw...) 


### WorldClim ###

# Weather
function geoarray(T::Type{<:WorldClim{Weather}}, layer::Symbol; date, kw...)
    GDALarray(getraster(T, layer; date=date); kw...)
end
function stack(T::Type{WorldClim{Weather}}, layers::LayerItr=layers(T); date, kw...)
    GDALstack(map(l -> getraster(T, l; date=date), layers); keys=layers, kw...)
end
function series(T::Type{WorldClim{Weather}}, layers::LayerItr=layers(T); date, window=(), kw...)
    step = Month(1)
    dates = _date_sequence(date, step)
    timedim = Ti(dates; mode=Sampled(Ordered(), Regular(step), Intervals(Start())))
    stacks = [stack(T, layers; date=d, window=window) for d in dates]
    GeoData.GeoSeries(stacks, timedim; kw...)
end

# Climate
function geoarray(T::Type{<:WorldClim{Climate}}, layer::Symbol; month, res=defres(T), kw...)
    GDALarray(getraster(T, layer; res=res, month=month); kw...)
end
function stack(T::Type{WorldClim{Climate}}, layers::LayerItr=layers(T); month, res=defres(T), kw...)
    filenames = map(l -> getraster(T, l; res=res, month=month), layers)
    GDALstack(filenames; keys=layers, kw...)
end
function series(T::Type{WorldClim{Climate}}, layers::LayerItr=layers(T);
    res=defres(T), month=1:12, window=(), kw...
)
    timedim = Ti(month; mode=Sampled(span=Regular(1), sampling=Intervals(Start())))
    stacks = [stack(T, layers; res=res, month=m, window=window) for m in month]
    GeoData.GeoSeries(stacks, timedim; kw...)
end

# BioClim
function geoarray(T::Type{<:WorldClim{BioClim}}, layer::Int; res=defres(T), kw...)
    GDALarray(getraster(T, layer; res=res); kw...)
end
function stack(T::Type{WorldClim{BioClim}}, layers::LayerItr=layers(T); res=defres(T), kw...)
    filenames = [getraster(T, l; res=res) for l in layers]
    GDALstack(filenames; keys=_asbioclim(layers), kw...)
end

_asbioclim(ns) = map(_asbioclim, ns)
_asbioclim(n::Int) = string("BIO", n)

#### CHELSA ####

# BioClim
function geoarray(T::Type{<:CHELSA{BioClim}}, layer::Int; kw...)
    GDALarray(getraster(T, layer); kw...)
end
function stack(T::Type{CHELSA{BioClim}}, layers::LayerItr=layers(T); kw...)
    filenames = [getraster(T, l) for l in layers]
    GDALstack(filenames; keys=_asbioclim(layers), kw...)
end

#### EarthEnv ####

# HabitatHeterogeneity
function geoarray(T::Type{<:EarthEnv{HabitatHeterogeneity}}, layer::Symbol; res=defres(T), kw...)
    GDALarray(getraster(T, layer; res=res); kw...)
end
function stack(T::Type{EarthEnv{HabitatHeterogeneity}}, layers::LayerItr=layers(T); res=defres(T), kw...)
    filenames = [getraster(T, l; res=res) for l in layers]
    GDALstack(filenames; keys=layers, kw...)
end

# LandCover
function geoarray(T::Type{<:EarthEnv{LandCover}}, layer::Int; discover=false, kw...)
    GDALarray(getraster(T, layer; discover=discover); kw...)
end
function stack(T::Type{EarthEnv{LandCover}}, layers::LayerItr=layers(T); discover=false, kw...)
    filenames = [getraster(T, l; discover=discover) for l in layers]
    GDALstack(filenames; keys=layers, kw...)
end

#### ALWB ####

function geoarray(T::Type{<:ALWB}, layer::Symbol; date::TimeType, kw...)
    NCDarray(getraster(T, layer; date=date), layer; kw...)
end
function stack(T::Type{<:ALWB}, layers::LayerItr=layers(T); date, kw...)
    filenames = [getraster(T, l; date=date) for l in layers]
    NCDstack(filenames; keys=layers, kw...)
end
function series(T::Type{<:ALWB{M,P}}, layers::LayerItr=layers(T); date, window=(), kw...) where {M,P}
    step = P(1)
    dates = _date_sequence(date, step)
    timedim = Ti(dates; mode=Sampled(span=Regular(step), sampling=Intervals(Start())))
    stacks = [stack(T, layers; date=d, window=window) for d in dates]
    GeoData.GeoSeries(stacks, timedim; kw...)
end

#### AWAP ####

# AWAP asciii files don't have crs and BOM don't specify what it is besides
# being evenly spaced lat/lon. So we assume it's EPSG(4326) and set it manually
function geoarray(T::Type{AWAP}, layer; date, kw...)
    GDALarray(getraster(T, layer; date=date); crs=EPSG(4326), kw...)
end
function stack(T::Type{AWAP}, layers::LayerItr=layers(T); date, kw...)
    GDALstack(map(l -> getraster(T, l; date=date), layers);
        childkwargs=(crs=EPSG(4326),), keys=layers, kw...
    )
end
function series(T::Type{AWAP}, layers::LayerItr=layers(T); date, window=(), kw...)
    step = Day(1)
    dates = _date_sequence(date, step)
    timedim = Ti(dates; mode=Sampled(span=Regular(step), sampling=Intervals(Start())))
    stacks = [stack(T, layers; date=d, window=window) for d in dates]
    GeoData.GeoSeries(stacks, timedim; kw...)
end
