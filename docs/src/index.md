# RasterDataSources.jl

```@docs
RasterDataSources
```

# getraster

RasterDataSources.jl only exports a single function, `getraster`.

```@docs
getraster
```

Specific implementations are included with each source, below.


# Data sources

```@docs
RasterDataSources.RasterDataSource
```

## ALWB

```@docs
ALWB
getraster(T::Type{<:ALWB}, layers::Union{Tuple,Symbol}; date)
```

## AWAP

```@docs
AWAP
getraster(T::Type{AWAP}, layer::Union{Tuple,Symbol}; date)
```

## CHELSA

```@docs
CHELSA
getraster(T::Type{CHELSA{BioClim}}, layer::Union{Tuple,Int,Symbol})
getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layers::Union{Tuple,Symbol}; date, month)
```

## EarthEnv

```@docs
EarthEnv
getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, layers::Union{Tuple,Symbol}; res)
getraster(T::Type{EarthEnv{LandCover}}, layers::Union{Tuple,Int,Symbol}; res)
```

## WorldClim

```@docs
WorldClim
getraster(T::Type{WorldClim{BioClim}}, layers::Union{Tuple,Int,Symbol}; res)
getraster(T::Type{WorldClim{Weather}}, layers::Union{Tuple,Symbol}; date)
getraster(T::Type{WorldClim{Climate}}, layers::Union{Tuple,Symbol}; month, res)
```

## MODIS

```
# WIP
```

# Datasets

```@docs
RasterDataSources.RasterDataSet
BioClim
Climate
Weather
LandCover
HabitatHeterogeneity
Future
```

# Models, phases and scenarios for [`Future`](@ref) data.

```@docs
RasterDataSources.ClimateModel
RasterDataSources.CMIPphase 
CMIP5
CMIP6
RasterDataSources.ClimateScenario 
RasterDataSources.RepresentativeConcentrationPathway
RasterDataSources.SharedSocioeconomicPathway
```

# Other

```@docs
Values
Deciles
```

# Internal interface

These methods are not exported at this stage, but are for the most part
internally consistent. Any new sources added to the package should use these
methods in a consistent way for readability, consistency and the potential to use
them for other things later.

```@autodocs
Modules = [RasterDataSources]
Public = false
Order = [:function]
```
