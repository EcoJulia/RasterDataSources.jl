abstract type BiodiversityMappingClade end

struct Amphibians{X,Y} <: BiodiversityMappingClade end
struct Birds{X,Y} <: BiodiversityMappingClade end
struct Mammals{X,Y} <: BiodiversityMappingClade end

"""
    BiodiversityMapping{Union{Amphibians, Birds, Mammals}} <: RasterDataSource

See: https://biodiversitymapping.org/index.php/download/
"""
struct BiodiversityMapping{X} <: RasterDataSource end
