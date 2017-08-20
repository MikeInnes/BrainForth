module BrainForth

using MacroTools

include("brainfuck.jl")
include("bootstrap.jl")
include("forth.jl")
include("array.jl")
include("text.jl")
include("utils.jl")

end # module
