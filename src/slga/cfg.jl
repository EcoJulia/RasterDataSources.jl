const SLGA_CFG_DATE   = "20221006"
const SLGA_CFG_SUFFIX = "_N_P_AU_TRN_N"

# Coarse fragment volume class definitions (% vol, >=2 mm particles)
const SLGA_CFG_CLASSES = (
    class1   = (description="Coarse fragments probability: class 1 (0–2% vol)",   range="0-2"),
    class2   = (description="Coarse fragments probability: class 2 (2–10% vol)",  range="2-10"),
    class3   = (description="Coarse fragments probability: class 3 (10–20% vol)", range="10-20"),
    class4   = (description="Coarse fragments probability: class 4 (20–35% vol)", range="20-35"),
    class5   = (description="Coarse fragments probability: class 5 (35–60% vol)", range="35-60"),
    class6   = (description="Coarse fragments probability: class 6 (>60% vol)",   range=">60"),
    dominant = (description="Dominant coarse fragment class (1–6)",               range="1-6"),
)

depths(::Type{SLGA_CFG}) = SLGA_DEPTHS
getraster_keywords(::Type{SLGA_CFG}) = (:depth,)

rasterpath(::Type{SLGA_CFG}) = joinpath(rasterpath(), "SLGA", "cfg")

function rasternames(::Type{SLGA_CFG}; depth)
    dcode = SLGA_DEPTH_CODES[depth]
    base  = "CFG_$(dcode)_EV$(SLGA_CFG_SUFFIX)_$(SLGA_CFG_DATE)"
    (
        class1   = "$(base)_CF_Probability_Class1.tif",
        class2   = "$(base)_CF_Probability_Class2.tif",
        class3   = "$(base)_CF_Probability_Class3.tif",
        class4   = "$(base)_CF_Probability_Class4.tif",
        class5   = "$(base)_CF_Probability_Class5.tif",
        class6   = "$(base)_CF_Probability_Class6.tif",
        dominant = "$(base)_Dominant_Class.tif",
    )
end

function rasterpaths(T::Type{SLGA_CFG}; depth)
    base = rasterpath(T)
    map(fname -> joinpath(base, fname), rasternames(T; depth))
end

function rasterurls(T::Type{SLGA_CFG}; depth)
    map(fname -> joinpath(SLGA_URI, "CFG", fname), rasternames(T; depth))
end

function getraster(T::Type{SLGA_CFG}; depth="0-5cm")
    depth in depths(T) || throw(ArgumentError(
        "Depth \"$depth\" is not valid for SLGA_CFG. Valid depths: $(join(depths(T), ", "))"))
    paths = rasterpaths(T; depth)
    urls  = rasterurls(T; depth)
    map(_maybe_download, urls, paths)
end

function getraster(T::Type{SLGA_CFG}; depth::AbstractArray)
    map(d -> getraster(T; depth=d), depth)
end
