# Exported

"""
    getraster(source::Type, [layer]; kw...)

`getraster` provides a standardised interface to download data sources,
and return the filename/s of the selected files.

RasterDataSources.jl aims to standardise an API for downloading many kinds of raster files
from many sources, that can be wrapped by other packages (such as Rasters.jl and
SimpleSDMLayers.jl) in a simple, regular way. As much as possible it will move towards
having less source-specific keywords wherever possible. Similar datasets will behave in the
same way so that they can be used interchangeably in the same code.

# Arguments

- `source`: defines the [`RasterDataSource`](@ref) and (if it there is more than one)
    the specific [`RasterDataSet`](@ref) from which to download data.
- `layer`: optionally choose the named or numbered layer/s of the data source.
    If only the source argument is passed, all layers will be downloaded, returning a
    `Tuple` of filenames.

# Keywords

Keyword arguments specify subsets of a data set, such as by date or resolution.
As much as possible these are standardised for all sources where they are relevent.

- `date`: `DateTime` date, range of dates, or tuple of start and end dates. Usually for weather datasets.
- `month`: month or range of months to download for climatic datasets, as `Integer`s from 1 to 12.
- `res`: spatial resolion of the file, as a `String` with units, e.g. "10m".

The return value is either a single `String`, a `Tuple/Array` of `String`, or a
`Tuple/Array` of `Tuple/Array` of `String` --- depending on the arguments. If multiple
layers are specified, this may return multiple filenames. If multiple months or dates are
specified, this may also return multiple filenames.
"""
function getraster end


# Not exported, but relatively consistent and stable
# These should be used for consistency accross all sources

"""
    rastername(source::Type, [layer]; kw...)

Returns the name of the file, without downloading it.

Arguments are the same as for `getraster`

Returns a `String` or multiple `Strings`.
"""
function rastername end

"""
    rasterpath(source::Type, [layer]; kw...)

Returns the name of the file, without downloading it.

Arguments are the same as for `getraster`

Returns a `String` or multiple `Strings`.
"""
function rasterpath end

"""
    rasterurl(source::Type, [layer]; kw...)

If the file has a single url, returns it without downloading.

Arguments are the same as for `getraster`.

Returns a URIs.jl `URI` or mulitiple `URI`s.
"""
function rasterurl end

"""
    zipname(source::Type, [layer]; kw...)

If the url is a zipped file, returns its name.

Arguments are as the same for `getraster` where possible.

Returns a `String` or multiple `Strings`.
"""
function zipname end

"""
    zippath(source::Type, [layer]; kw...)

If the url is a zipped file, returns its path when downloaded.
(This may not exist after extraction with `getraster`)

Arguments are the same as for `getraster` where possible.

Returns a `String` or multiple `Strings`.
"""
function zippath end

"""
    zipurl(source::Type, [layer]; kw...)

If the url is a zipped file, returns its zip path without downloading.

Arguments are the same as for `getraster` where possible.

Returns a URIs.jl `URI` or mulitiple `URI`s.
"""
function zipurl end
