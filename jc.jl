module JuliaCheck

import Pkg
Pkg.add(Pkg.PackageSpec(name="JuliaSyntax", version="1.0"))

import JuliaSyntax as JSx
using JuliaSyntax: ParseError, SourceFile, SyntaxNode, Kind, @K_str, @KSet_str,
    children, head, kind

export Node, display


## Types ##
Node = JSx.SyntaxNode

## Functions ##
display(branch::Node) = show(stdout, MIME"text/plain"(), branch)

include("violations.jl")
include("symbol_table.jl")
include("properties.jl")

# Checks
include("check_avoid_globals.jl")
include("check_space_around_infix_operators.jl")

include("process.jl")
export check

end     # module JuliaCheck
