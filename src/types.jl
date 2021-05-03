"""
    RasterDataSource 

Abstract supertype for raster data collections.  
"""
abstract type RasterDataSource end

"""
    RasterDataSet

Abstract supertye for datasets that belong to a [`RasterDataSource`](@ref).
"""
abstract type RasterDataSet end

"""
    BioClim <: RasterDataSet

BioClim datasets. Usually containing layers from 1:19. They do not use
`month` or `date` keywords, but may allow `res` to be specified.
"""
struct BioClim <: RasterDataSet end

"""
    Climate <: RasterDataSet

Climate datasets. These are usually months of the year, not specific dates,
and use a `month` keyword in `getraster`.
"""
struct Climate <: RasterDataSet end

"""
    Weather <: RasterDataSet

Weather datasets. These are usually large time-series of specific dates,
and use a `date` keyword in `getraster`.
"""
struct Weather <: RasterDataSet end

"""
    LandCover <: RasterDataSet

Land-cover datasets.
"""
struct LandCover <: RasterDataSet end

"""
    HabitatHeterogeneity <: RasterDataSet

Habitat heterogeneity datasets.
"""
struct HabitatHeterogeneity <: RasterDataSet end
