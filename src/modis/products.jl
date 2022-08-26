"""
    This file contains functions to handle MODIS product info.

Depending on missions and products, MODIS data does not have the
same layers.
"""

"""
    product(T::Type{<:ModisProduct})

Extracts `ModisProduct` product name as a `String`
"""
function product(T::Type{<:ModisProduct})
    return String(nameof(T))
end

"""
    Lists available layers for a given MODIS Product

Looks in `joinpath(ENV["RASTERDATASOURCES_PATH"]/MODIS/layers` for
a file with the right name. If not found, sends a request to the server
to get the list.

This allows to make as many internal calls of layers() and layerkeys() as
needed without issuing a lot of requests.
"""
function list_layers(T::Type{<:ModisProduct})

    prod = product(T)

    path = joinpath(ENV["RASTERDATASOURCES_PATH"], "MODIS/layers", prod * ".csv")

    if isfile(path)
        layers = open(path, "r") do f
            readline(f)
        end
    else # if not on disk we download layers info

        @info "Starting download of layers list for product $prod"
        mkpath(dirname(path))
        r = HTTP.download(
            join([string(MODIS_URI), prod, "bands"], "/"),
            path,
            ["Accept" => "text/csv"],
        )

        # read downloaded file
        layers = open(path, "r") do f
            readline(f)
        end

    end

    return split(String(layers), ",")
end

"""
    List available dates for a MODIS product at given coordinates
"""
function list_dates(
    T::Type{<:ModisProduct};
    lat::Real,
    lon::Real,
    from::Union{String,Date} = "all", # might be handy
    to::Union{String,Date} = "all",
    format::String = "Date",
)

    prod = product(T)

    filepath =
        joinpath(rasterpath(), "MODIS/dates", string(lat) * "," * string(lon) * ".csv")

    if !isfile(filepath) # we need to download dates from the server

        mkpath(dirname(filepath))
        @info "Requesting availables dates for product $prod at $lat , $lon"

        ## Get all dates at given point
        # request
        r = HTTP.request(
            "GET",
            join([string(MODIS_URI), prod, "dates"], "/"),
            query = Dict("latitude" => string(lat), "longitude" => string(lon)),
        )

        # parse
        body = JSON.parse(String(r.body))
        
        # prebuild columns
        calendardates = String[]
        modisdates = String[]

        # fill the DataFrame
        for date in body["dates"]
            push!(calendardates, date["calendar_date"])
            push!(modisdates, date["modis_date"])
        end

        open(filepath, "w") do f
            writedlm(f, [calendardates modisdates], ',')
        end
    else # a file with dates is already downloaded
        # we simply read the file
        mat = readdlm(filepath, ',', String)
        calendardates = mat[:, 1]
        modisdates = mat[:, 2]
    end

    ## Filter for dates between from and to arguments

    calendardates = Date.(calendardates)

    from == "all" && (from = calendardates[1])
    to == "all" && (to = calendardates[end])

    startfound, endfound = false, false
    bounds = [0,0]
    i = 1
    while !endfound
        # two ways to find the end:
        if i == length(calendardates) # end of vector reached
            endfound = true
            bounds[2] = i
        elseif calendardates[i] > Date(to) && i > 1 # to reached
            # if dates[i] is just over "to", dates[i-1] is the margin
            endfound = true
            bounds[2] = i-1
        end

        if !startfound
            if calendardates[i] >= Date(from)
                startfound = true
                bounds[1] = i
            end
        end

        i += 1
    end

    if format == "ModisDate"
        return modisdates[bounds[1]:bounds[2]]
    else
        return calendardates[bounds[1]:bounds[2]]
    end
end
