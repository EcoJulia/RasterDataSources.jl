# RasterDataSources.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://cesaraustralia.github.io/RasterDataSources.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://cesaraustralia.github.io/RasterDataSources.jl/dev)
![CI](https://github.com/cesaraustralia/RasterDataSources.jl/workflows/CI/badge.svg)
[![codecov.io](http://codecov.io/github/cesaraustralia/RasterDataSources.jl/coverage.svg?branch=master)](http://codecov.io/github/cesaraustralia/RasterDataSources.jl?branch=master)

This package downloads raster data sourcess for use directly or by other Julia
packages. The collection is largely focussed on datasets relevent
to ecology, but will have a lot of crossover with other sciences.

RasterDataSources was based on code from the `SimpleSDMDataSoures` 
package by Timothée Poisot.

## Example

First, to specify the directory in which the data is to be downloaded, modify your `startup.jl` file located in your `Julia` install directory (e.g. `Julia\Julia 1.5.2\etc\julia\startup.jl`) to include the following line:

`ENV["RASTERDATASOURCES_PATH"] = "\MyDataLocation"`

Then run the following code:

```julia
#lolad packages
using RasterDataSources, Dates, GeoData
using RasterDataSources: Values, SoilMoisture, Upper, Lower

# download montly mean tavg data from WorldClim at the 10 m resoltution
layers = (:tavg, )
months = 1:12
download_raster(WorldClim{Climate}, layers; resolution = "10m", month=months)

# make GeoSeries
ser = series(WorldClim{Climate}; layers=layers)

```
