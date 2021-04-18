# RasterDataSources.jl

```@docs
RasterDataSources
```

# getraster

RasterDataSources.jl only exports a single function, `getraster`.

```@autodocs
Modules = [RasterDataSources]
Private = false
Order = [:function]
```

# Data sources

```@docs
RasterDataSources.RasterDataSource
ALWB
AWAP
CHELSA
EarthEnv
WorldClim
```

# Datasets

```@docs
RasterDataSources.RasterDataSet
BioClim
Climate
Weather
LandCover
HabitatHeterogeneity
```

# Other

```julia
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
