
layers(::Type{<:CHELSA{<:Future{BioClim}}}) = 1:19
layers(::Type{<:CHELSA{<:Future{Climate}}}) = (:prec, :temp, :tmin, :tmax)

# A modified key is used in the file name, while the key is used as-is in the path
const CHELSAKEY = (prec="pr", temp="tas", tmin="tasmin", tmax="tasmax", bio="bio")

"""
    getraster(T::Type{CHELSA{Future{BioClim}}}, [layer::Integer]; date) => String

Download CHELSA BioClim data, choosing layers from: `$(layers(CHELSA{BioClim}))`.

Without a layer argument, all layers will be downloaded, and a tuple of paths is returned.
If the data is already downloaded the path will be returned.

## Keywords
- `date`: A `Date` or `DateTime` object. Note that CHELSA CMIP5 only has two datasets,
    for the periods 2041-2060 and 2061-2080. Dates must fall in these ranges
"""
function getraster(T::Type{<:CHELSA{<:Future{BioClim}}}, layer::Integer; date=Date(2050))
    _getraster(T, layer; date)
end
"""
    getraster(T::Type{CHELSA{Future{Climate}}}, [layer::Integer]; date, month) => String

Download CHELSA BioClim data, choosing layers from: `$(layers(CHELSA{BioClim}))`.

Without a layer argument, all layers will be downloaded, and a tuple of paths is returned.
If the data is already downloaded the path will be returned.

## Keywords
- `date`: A `Date` or `DateTime` object. Note that CHELSA CMIP5 only has two datasets,
    for the periods 2041-2060 and 2061-2080. Dates must fall in these ranges
- `month`: The month of the year, defaulting to all months, `1:12`.
"""
function getraster(
    T::Type{<:CHELSA{<:Future{Climate}}}, layer::Symbol; date=Date(2050), month=1:12
)
    _getraster(T, layer, date, month)
end

function _getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layer, date, months::AbstractArray)
    map(month -> _getraster(T, layer, date, month), months)
end
function _getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layer, dates::AbstractArray, month)
    map(date -> _getraster(T, layer; date, month), dates)
end
function _getraster(
    T::Type{<:CHELSA{<:Future{Climate}}}, layer, dates::AbstractArray, months::AbstractArray
)
    map(month -> _getraster(T, layer, dates, month), months)
end
function _getraster(T::Type{<:CHELSA{<:Future{Climate}}}, layer, date, month)
    _getraster(T, layer; date, month)
end

function _getraster(T::Type{<:CHELSA{<:Future}}, layer; kw...)
    _check_layer(T, layer)
    path = rasterpath(T, layer; kw...)
    url = rasterurl(T, layer; kw...)
    return _maybe_download(url, path)
end

function rastername(T::Type{<:CHELSA{<:Future}}, layer; kw...)
    _rastername(_phase(T), T, layer; kw...)
end

function _rastername(
    ::Type{CMIP5}, T::Type{<:CHELSA{<:Future{BioClim}}}, layer::Integer; date
)
    date_string = _date_string(_phase(T), date)
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    return "CHELSA_bio_mon_$(mod)_$(scen)_r1i1p1_g025.nc_$(layer)_$(date_string)_V1.2.tif"
end
function _rastername(
    ::Type{CMIP5}, T::Type{<:CHELSA{<:Future{Climate}}}, layer::Symbol; date, month
)
    date_string = _date_string(_phase(T), date)
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    key = CHELSAKEY[layer]
    suffix = layer === :prec ? "" : "_V1.2" # prec filenames dont end in _V1.2
    return "CHELSA_$(key)_mon_$(mod)_$(scen)_r1i1p1_g025.nc_$(month)_$(date_string)$(suffix).tif"
end
function _rastername(::Type{CMIP6}, T::Type{<:CHELSA{<:Future{BioClim}}}, layer::Integer; date)
    date_string = _date_string(_phase(T), date)
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    return "CHELSA_bio$(layer)_$(date_string)_$(mod)_$(scen)_V.2.1.tif"
end
function _rastername(
    ::Type{CMIP6}, T::Type{<:CHELSA{<:Future{Climate}}}, layer::Symbol; date, month
)
    # CMIP6 Climate uses an underscore in the date string, of course
    date_string = replace(_date_string(_phase(T), date), "-" => "_")
    mod = _format(CHELSA, _model(T))
    scen = _format(CHELSA, _scenario(T))
    key = CHELSAKEY[layer]
    mon = lpad(month, 2, '0')
    return "CHELSA_$(mod)_r1i1p1f1_w5e5_$(scen)_$(key)_$(mon)_$(date_string)_norm.tif"
end

function rasterpath(T::Type{<:CHELSA{<:Future}})
    joinpath(rasterpath(CHELSA), "Future", string(_dataset(T)), string(_scenario(T)), string(_model(T)))
end
function rasterpath(T::Type{<:CHELSA{<:Future}}, layer; kw...)
    joinpath(rasterpath(T), rastername(T, layer; kw...))
end

function rasterurl(T::Type{<:CHELSA{<:Future}}, layer; date, kw...)
    date_str = _date_string(_phase(T), date)
    key = _chelsa_layer(_dataset(T), layer)
    path = _urlpath(_phase(T), T::Type{<:CHELSA{<:Future}}, key, date_str)
    joinpath(rasterurl(CHELSA), path, rastername(T, layer; date, kw...))
end

_chelsa_layer(::Type{<:BioClim}, layer) = :bio
_chelsa_layer(::Type{<:Climate}, layer) = layer

function _urlpath(::Type{CMIP5}, T::Type{<:CHELSA{<:Future}}, name, date_str)
    return "chelsa_V1/cmip5/$date_str/$name/"
end
function _urlpath(::Type{CMIP6}, T::Type{<:CHELSA{<:Future}}, name, date_str)
    # The model is in uppercase in the URL for CMIP6
    mod = uppercase(_format(CHELSA, _model(T)))
    scen = _format(CHELSA, _scenario(T))
    key = CHELSAKEY[name]
    return "chelsa_V2/GLOBAL/climatologies/$date_str/$mod/$scen/$key/"
end

function _date_string(::Type{CMIP5}, date)
    if date < DateTime(2041)
        _cmip5_date_error(date)
    elseif date < DateTime(2061)
        "2041-2060"
    elseif date < DateTime(2081)
        "2061-2080"
    else
        _cmip5_date_error(date)
    end
end

function _date_string(::Type{CMIP6}, date)
    if date < DateTime(1981)
        _cmip5_date_error(date)
    elseif date < DateTime(2011)
        "1981-2010"
    elseif date < DateTime(2041)
        "2011-2040"
    elseif date < DateTime(2071)
        "2041-2070"
    elseif date < DateTime(2101)
        "2071-2100"
    else
        _cmip6_date_error(date)
    end
end

_cmip5_date_error(date) = error("CMIP5 covers the period from 2041-2080, not $date")
_cmip6_date_error(date) = error("CMIP6 covers the period from 1981-2100, not $date")

_dataset(::Type{<:CHELSA{F}}) where F<:Future = _dataset(F)
_phase(::Type{<:CHELSA{F}}) where F<:Future = _phase(F)
_model(::Type{<:CHELSA{F}}) where F<:Future = _model(F)
_scenario(::Type{<:CHELSA{F}}) where F<:Future = _scenario(F)

# Climate model string formatters for CHELSA Future

# CMIP5
_format(::Type{CHELSA}, ::Type{ACCESS1}) = "ACCESS1-0"
_format(::Type{CHELSA}, ::Type{BNUESM}) = "BNU-ESM"
_format(::Type{CHELSA}, ::Type{CCSM4}) = "CCSM4"
_format(::Type{CHELSA}, ::Type{CESM1BGC}) = "CESM1-BGC"
_format(::Type{CHELSA}, ::Type{CESM1CAM5}) = "CESM1-CAM5"
_format(::Type{CHELSA}, ::Type{CMCCCMS}) = "CMCC-CMS"
_format(::Type{CHELSA}, ::Type{CMCCCM}) = "CMCC-CM"
_format(::Type{CHELSA}, ::Type{CNRMCM5}) = "CNRM-CM5"
_format(::Type{CHELSA}, ::Type{CSIROMk3}) = "CSIRO-Mk3"
_format(::Type{CHELSA}, ::Type{CanESM2}) = "CanESM2"
_format(::Type{CHELSA}, ::Type{FGOALS}) = "FGOALS-g2"
_format(::Type{CHELSA}, ::Type{FIOESM}) = "FIO-ESM"
_format(::Type{CHELSA}, ::Type{GFDLCM3}) = "GFDL-CM3"
_format(::Type{CHELSA}, ::Type{GFDLESM2G}) = "GFDL-ESM2G"
_format(::Type{CHELSA}, ::Type{GFDLESM2M}) = "GFDL-ESM2M"
_format(::Type{CHELSA}, ::Type{GISSE2HCC}) = "GISS-E2-H-CC"
_format(::Type{CHELSA}, ::Type{GISSE2H}) = "GISS-E2-H"
_format(::Type{CHELSA}, ::Type{GISSE2RCC}) = "GISS-E2-R-CC"
_format(::Type{CHELSA}, ::Type{GISSE2R}) = "GISS-E2-R"
_format(::Type{CHELSA}, ::Type{HadGEM2AO}) = "HadGEM2-AO"
_format(::Type{CHELSA}, ::Type{HadGEM2CC}) = "HadGEM2-CC"
_format(::Type{CHELSA}, ::Type{IPSLCM5ALR}) = "IPSL-CM5A-LR"
_format(::Type{CHELSA}, ::Type{IPSLCM5AMR}) = "IPSL-CM5A-MR"
_format(::Type{CHELSA}, ::Type{MIROCESMCHEM}) = "MIROC-ESM-CHEM"
_format(::Type{CHELSA}, ::Type{MIROCESM}) = "MIROC-ESM"
_format(::Type{CHELSA}, ::Type{MIROC5}) = "MIROC5"
_format(::Type{CHELSA}, ::Type{MPIESMLR}) = "MPI-ESM-LR"
_format(::Type{CHELSA}, ::Type{MPIESMMR}) = "MPI-ESM-MR"
_format(::Type{CHELSA}, ::Type{MRICGCM3}) = "MRI-CGCM3"
_format(::Type{CHELSA}, ::Type{MRIESM1}) = "MRI-ESM1"
_format(::Type{CHELSA}, ::Type{NorESM1M}) = "NorESM1-M"
_format(::Type{CHELSA}, ::Type{BCCCSM1}) = "bcc-csm-1"
_format(::Type{CHELSA}, ::Type{Inmcm4}) = "inmcm4"

# CMIP6
_format(::Type{CHELSA}, ::Type{GFDLESM4}) = "gfdl-esm4"
_format(::Type{CHELSA}, ::Type{IPSLCM6ALR}) = "ipsl-cm6a-lr"
_format(::Type{CHELSA}, ::Type{MPIESMHR}) = "mpi-esm1-2-hr"
_format(::Type{CHELSA}, ::Type{MRIESM2}) = "mri-esm2-0"
_format(::Type{CHELSA}, ::Type{UKESM}) = "ukesm1-0-ll"

# Format scenarios
_format(::Type{CHELSA}, ::Type{RCP26}) = "rcp26"
_format(::Type{CHELSA}, ::Type{RCP45}) = "rcp45"
_format(::Type{CHELSA}, ::Type{RCP60}) = "rcp60"
_format(::Type{CHELSA}, ::Type{RCP85}) = "rcp85"

_format(::Type{CHELSA}, ::Type{SSP126}) = "ssp126"
_format(::Type{CHELSA}, ::Type{SSP245}) = "ssp245"
_format(::Type{CHELSA}, ::Type{SSP370}) = "ssp370"
_format(::Type{CHELSA}, ::Type{SSP585}) = "ssp585"
