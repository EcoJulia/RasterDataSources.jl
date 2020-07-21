"""
    worldclim(layer::Integer; resolution::Float64=10.0, left=nothing, right=nothing, bottom=nothing, top=nothing)

Download and prepare a WorldClim 2.1 bioclimatic variable, and returns it as an
`SimpleSDMPredictor`. Layers are called by their number, from 1 to 19. The list
of available layers is given in a table below.

The keywords are `resolution`, which must be a floating point value, and either
`2.5`, `5.0`, or `10.0`, as well as optionally `left`, `right`, `bottom`, and
`top`, which will allow to only load parts of the data.

Internally, this function will download the main zip file for the required
resolution from the WordlClim website, extract it, and parse the required
layers.

It is recommended to *keep* the content of the `path` folder, as it will
eliminate the need to download and/or extract the tiff files. For example,
calling `wordlclim(1:19)` will download and extract everything, and future calls
will be much faster.

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

Original data: https://www.worldclim.org/data/worldclim21.html
"""
function worldclim(layer::Integer; resolution::Float64=10.0, left=nothing, right=nothing, bottom=nothing, top=nothing)
    return raster(SimpleSDMPredictor, WorldClim(resolution), layer=layer, left=left, right=right, bottom=bottom, top=top)
end

worldclim(layers::Vector{T}; args...) where {T <: Integer} = [worldclim(l; args...) for l in layers]
worldclim(layers::UnitRange{T}; args...) where {T <: Integer} = [worldclim(l; args...) for l in layers]
