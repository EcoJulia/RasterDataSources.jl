"""
    RasterDataSource Abstract supertype for raster data collections.  """
abstract type RasterDataSource end

"""
    RasterDataSet

Abstract supertye for datasets that belong to a in a [`RasterDataSource`](@ref).
"""
abstract type RasterDataSet end

"""
    BioClim <: RasterDataSet

BioClim datasets. Usually containing 19 numbered layers.
"""
struct BioClim <: RasterDataSet end

"""
    Climate <: RasterDataSet

Climate datasets. These are usually months of the year, not specific dates.
"""
struct Climate <: RasterDataSet end

"""
    Weather <: RasterDataSet

Weather datasets. These are usually large time-series of specific dates.
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