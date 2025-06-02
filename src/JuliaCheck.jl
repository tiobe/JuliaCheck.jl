module JuliaCheck

import JuliaSyntax as JS

include("Process.jl")
import .Process

function main(args::Array{String})
    print_ast = print_llt = false
    for argument in args
        if argument == "-v"
            # Enable logging level debug for modules JuliaCheck and Main (this file)
            ENV["JULIA_DEBUG"] = "Main,JuliaCheck"
            # TODO: allow more granularity, to use level 'info' before 'debug',
            # or make an intermediate level (or one lower than 'debug').

        elseif argument == "-ast"
            print_ast = true

        elseif argument == "-llt"
            print_llt = true

        elseif !(Base.Filesystem.isfile(argument))
            @error ">> Error: cannot read '$argument' as a file."

        else
            print("\n>> Processing file '")
            printstyled(argument; color=:green)
            print("'...\n")
            Process.check(argument; show_ast=print_ast, show_llt=print_llt)
        end
    end
    println()
end

main(ARGS)

end
