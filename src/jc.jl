module JuliaCheck

import JuliaSyntax as JS
export display, validatesyntax

## Functions ##
display(branch::JS.SyntaxNode) = show(stdout, MIME"text/plain"(), branch)
display(branch::JS.GreenNode) = show(stdout, MIME"text/plain"(), branch)
# TODO: common argument to both?

# TODO: function to stringify a tree

# Checks
#include("check_space_around_infix_operators.jl")

validatesyntax(fname) = include(expr -> Meta.isexpr(expr, (:error, :incomplete)) ? expr : nothing, fname)

end     # module JuliaCheck
