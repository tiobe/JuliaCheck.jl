#!/usr/bin/env -S julia --color=yes --startup-file=no

include("JC.jl")

function main(args::Array{String})
    for argument in args
        if argument == "-v"
            # Enable logging level debug for modules JS and Main (this file)
            ENV["JULIA_DEBUG"] = "JS,Process,Main"
        elseif !(Base.Filesystem.isfile(argument))
            @error ">> Error: cannot read '$argument' as a file."
        else
            print("\n>> Processing file '")
            printstyled(argument; color=:green)
            print("'...\n")
            JuliaCheck.check(argument)
        end
    end
end

main(ARGS)
