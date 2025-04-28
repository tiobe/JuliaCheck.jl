#!/usr/bin/env -S julia --color=yes --startup-file=no
module JuliaCheck

import JuliaSyntax as JS
export display, to_string

## Functions ##
display(branch::JS.SyntaxNode) = show(stdout, MIME"text/plain"(), branch)
display(branch::JS.GreenNode)  = show(stdout, MIME"text/plain"(), branch)

to_string(branch::JS.SyntaxNode) = sprint(show, MIME("text/plain"), branch)
to_string(branch::JS.GreenNode)  = sprint(show, MIME("text/plain"), branch)

include("Process.jl")
import .Process

function main(args::Array{String})
    for argument in args
        if argument == "-v"
            # Enable logging level debug for modules JuliaCheck and Main (this file)
            ENV["JULIA_DEBUG"] = "Main,JuliaCheck"
        elseif !(Base.Filesystem.isfile(argument))
            @error ">> Error: cannot read '$argument' as a file."
        else
            print("\n>> Processing file '")
            printstyled(argument; color=:green)
            print("'...\n")
            Process.check(argument)
        end
    end
end

main(ARGS)

end
