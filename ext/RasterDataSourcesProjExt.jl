module RasterDataSourcesProjExt

import Proj
import RasterDataSources

function RasterDataSources.sinusoidal_to_latlon(x, y)
    transf = Proj.Transformation(
        "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371000 +units=m +no_defs +type=crs",
        "EPSG:4326";
        always_xy = true
    )
    transf(x, y)
end

function RasterDataSources.latlon_to_projected(wkt::AbstractString, lons, lats)
    transf = Proj.Transformation("EPSG:4326", wkt; always_xy = true)
    transf.(lons, lats)
end

end