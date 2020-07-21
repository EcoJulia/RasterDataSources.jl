module SimpleSDMDataSources

# Load the dependencies for this package
using ArchGDAL
using HTTP
using ZipFile

function _raster_assets_folder()
    project_path = dirname(something(Base.current_project(pwd()), Base.load_path_expand(LOAD_PATH[2])))
    assets_folder = joinpath(project_path, "assets")
    ispath(assets_folder) || mkdir(assets_folder)
    return assets_folder
end


end # module
