"""
Download and prepare bioclim layers from the CHELSA database, and returns
them as an array of `SimpleSDMPredictor`s. Layers are called by their number,
from 1 to 19. The list of available layers is given in a table below.

The keyword argument is `path`, which refers to the path where the function
will look for the geotiff files.

Note that these files are *large* due the fine resolution of the data, and for
this reason this function will return the *integer* version of the layers. Also
note that the bioclim data are only available for the V1 of CHELSA, and are not
from the V2.

It is recommended to *keep* the content of the `path` folder, as it will
eliminate the need to download the tiff files (which are quite large). For
example, calling `bioclim(1:19)` will download and everything, and future
calls will be much faster.

| Variable | Description                                                |
| ------   | ------                                                     |
| 1        | Annual Mean Temperature                                    |
| 2        | Mean Diurnal Range (Mean of monthly (max temp - min temp)) |
| 3        | Isothermality (BIO2/BIO7) (* 100)                          |
| 4        | Temperature Seasonality (standard deviation *100)          |
| 5        | Max Temperature of Warmest Month                           |
| 6        | Min Temperature of Coldest Month                           |
| 7        | Temperature Annual Range (BIO5-BIO6)                       |
| 8        | Mean Temperature of Wettest Quarter                        |
| 9        | Mean Temperature of Driest Quarter                         |
| 10       | Mean Temperature of Warmest Quarter                        |
| 11       | Mean Temperature of Coldest Quarter                        |
| 12       | Annual Precipitation                                       |
| 13       | Precipitation of Wettest Month                             |
| 14       | Precipitation of Driest Month                              |
| 15       | Precipitation Seasonality (Coefficient of Variation)       |
| 16       | Precipitation of Wettest Quarter                           |
| 17       | Precipitation of Driest Quarter                            |
| 18       | Precipitation of Warmest Quarter                           |
| 19       | Precipitation of Coldest Quarter                           |

"""
function bioclim(layer::Integer; left=nothing, right=nothing, bottom=nothing, top=nothing)
    return raster(SimpleSDMPredictor, BioClim(), layer=layer, left=left, right=right, bottom=bottom, top=top)
end

bioclim(layers::Vector{T}; args...) where {T <: Integer} = [bioclim(l; args...) for l in layers]
bioclim(layers::UnitRange{T}; args...) where {T <: Integer} = [bioclim(l; args...) for l in layers]
