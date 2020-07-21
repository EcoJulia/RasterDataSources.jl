using SimpleSDMDataSources
using Test

global anyerrors = false

tests = [
   "worldclim || bioclim" => "worldclim-bioclim.jl",
   "earthenv  || landcover" => "earthenv-landcover.jl"
   # "chelsa" => "chelsa.jl"
]

for test in tests
   try
      include(test.second)
      println("\033[1m\033[32m✓\033[0m\t$(test.first)")
   catch e
      global anyerrors = true
      println("\033[1m\033[31m×\033[0m\t$(test.first)")
      println("\033[1m\033[38m→\033[0m\ttest/$(test.second)")
      showerror(stdout, e, backtrace())
      println()
      break
   end
end

if anyerrors
   throw("Tests failed")
end
