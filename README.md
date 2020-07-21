# SimpleSDMDataSources.jl

This package works as a dependency of `SimpleSDMLayers`, and manages the
download of raster data from different sources. The main purpose of this
package is *only* to download the files that are required for `SimpleSDMLayers`
to do its job converting them into usable objects. This separation of download
code and manipulation code allows to accommodate a broader variety of data
sources. In particular, note that this package does *not* convert the files
into an `Array`.
