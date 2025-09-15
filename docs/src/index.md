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
```

## AWAP

```@docs
AWAP
```

## CHELSA

```@docs
CHELSA
```

## EarthEnv

```@docs
EarthEnv
```

## WorldClim

```@docs
WorldClim
```

## MODIS

```@docs
MODIS
ModisProduct
RasterDataSources.layerkeys(T::Type{<:ModisProduct})
```

# Datasets

```@docs
RasterDataSources.RasterDataSet
BioClim
BioClimPlus
Climate
Weather
Elevation
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

```@docs
RasterDataSources.layerkeys
RasterDataSources.rastername
RasterDataSources.rasterpath
RasterDataSources.rasterurl
RasterDataSources.zipname
RasterDataSources.zippath
RasterDataSources.zipurl
```

# Internal MODIS interface

Unlike all the other currently supported data sources, MODIS data is not
available online in raster file format. Building rasters out of the
available information therefore requires internal functions that are not
exported. They might be extended as needed if other similar sources get
supported.

### Requesting to server and building raster files

```@docs
RasterDataSources.modis_request
RasterDataSources.process_subset
```

### Miscellaneous

```@docs
RasterDataSources.product
RasterDataSources.sinusoidal_to_latlon
```
