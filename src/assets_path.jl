# Allow this to be set manually
function rasterpath() 
    if haskey(ENV, "RASTERDATASOURCES_PATH") && isdir(ENV["RASTERDATASOURCES_PATH"])
        ENV["RASTERDATASOURCES_PATH"]
    else
        error("You must set `ENV[\"RASTERDATASOURCES_PATH\"]` to a path in your system")
    end
end

# function _raster_assets_folder()
#     project_path = dirname(something(Base.current_project(pwd()), Base.load_path_expand(LOAD_PATH[2])))
#     assets_folder = joinpath(project_path, "assets", "general")
#     ispath(assets_folder) || mkpath(assets_folder)
#     return assets_folder
# end

# The folder structure could be more or less deeply nested than this

# function _raster_assets_folder(::Type{TS}, ::Type{TD}) where {TS <: RasterDataSource, TD <: RasterDataSet}
#     project_path = dirname(something(Base.current_project(pwd()), Base.load_path_expand(LOAD_PATH[2])))
#     assets_folder = joinpath(project_path, "assets", string(TS), string(TD))
#     ispath(assets_folder) || mkpath(assets_folder)
#     return assets_folder
# end

function cleanup_assets()
    # May need an "are you sure"? - this could be a lot of GB of data to lose
    ispath(rasterpath()) && rm(rasterpath())
end

function cleanup_assets(T::Type)
    ispath(rasterpath(T)) && rm(rasterpath(T))
end

function cleanup_assets(::Type{TS}, ::Type{TD}) where {TS <: RasterDataSource, TD <: RasterDataSet}
    ispath(_raster_assets_folder(TS, TD)) && rm(_raster_assets_folder(TS, TD); recursive=false)
end

