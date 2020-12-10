# RasterDataSources.jl

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
