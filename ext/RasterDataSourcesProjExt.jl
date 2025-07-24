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

end