# Generator for the Copernicus DEM tile coverage map in
# `src/copernicus_dem/coverage.txt`.
#
# Reads the authoritative `tileList.txt` published alongside each resolution's
# AWS Open Data bucket and writes a space-separated map of 1°×1° tiles, one row
# per degree of latitude (north at the top, 89° down to -90°), one column per
# degree of longitude (-180° to 179°). Each cell is a per-resolution bitmask:
# bit 1 (value 1) = tile exists in GLO-30 (30m), bit 2 (value 2) = tile exists
# in GLO-90 (90m). So 0 = open ocean, 3 = land (both resolutions), 2 = a tile
# present only in the 90m dataset (a handful in the Caucasus). The file is read
# back by `coverage.jl` with `DelimitedFiles.readdlm`.
#
# Re-run this when Copernicus publishes a new DEM version:
#   curl -s https://copernicus-dem-30m.s3.amazonaws.com/tileList.txt -o /tmp/cop30.txt
#   curl -s https://copernicus-dem-90m.s3.amazonaws.com/tileList.txt -o /tmp/cop90.txt
#   julia dev/gen_copernicus_coverage.jl

# Grid: row 1 = northernmost tile (SW corner lat 89, covering 89..90),
#       row 180 = southernmost (SW corner lat -90, covering -90..-89);
#       col 1 = westernmost (SW corner lon -180), col 360 = easternmost (lon 179).
const NLAT = 180
const NLON = 360

# SW-corner (lat, lon) integer degrees -> matrix (row, col)
_row(lat) = 90 - lat
_col(lon) = lon + 181

function parse_tile(line)
    # Copernicus_DSM_COG_10_N42_00_E011_00_DEM
    m = match(r"_(N|S)(\d{2})_00_(E|W)(\d{3})_00_DEM$", line)
    m === nothing && error("Unrecognised tile name: $line")
    ns, latd, ew, lond = m.captures
    lat = (ns == "S" ? -1 : 1) * parse(Int, latd)
    lon = (ew == "W" ? -1 : 1) * parse(Int, lond)
    return lat, lon
end

function coverage_from_list(path)
    M = falses(NLAT, NLON)
    for line in eachline(path)
        isempty(line) && continue
        lat, lon = parse_tile(line)
        M[_row(lat), _col(lon)] = true
    end
    return M
end

M30 = coverage_from_list("/tmp/cop30.txt")
M90 = coverage_from_list("/tmp/cop90.txt")

@info "tile counts" n30 = count(M30) n90 = count(M90) extra = count(M90 .& .!M30)

open(joinpath(@__DIR__, "..", "src", "copernicus_dem", "coverage.txt"), "w") do io
    for r in 1:NLAT
        println(io, join((Int(M30[r, c]) | (Int(M90[r, c]) << 1) for c in 1:NLON), ' '))
    end
end

println("Wrote src/copernicus_dem/coverage.txt")
