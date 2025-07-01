module JuliaCheck

import JuliaSyntax as JS
using ArgParse: ArgParseSettings, project_version, @add_arg_table!, parse_args

include("Properties.jl"); import .Properties

include("Checks.jl"); import .Checks: filter_rules

include("Process.jl"); import .Process

function parse_commandline(args::Vector{String})
    s = ArgParseSettings(
            description = "Code checker for Julia programming language.",
            epilog = """
            If you '--enable' a list of rules, separate it from the list of input files with '--'.
            """,
            add_version = true, version = project_version(joinpath(@__DIR__, "..", "Project.toml")))

    @add_arg_table! s begin
        "--enable"
            help = "List of rules to check on the given files."
            arg_type = String
            nargs = '+'
            dest_name = "rules"
        "--verbose", "-v"
            help = "Print debugging information."
            action = :store_true
        "--ast"
            help = "Print syntax tree for each input file."
            action = :store_true
        "--llt"
            help = "Print lossless tree for each input file."
            action = :store_true
        "infiles"
            help = "One or more Julia files to check with available rules."
            nargs = '+'
            arg_type = String
            required = true
    end

    return parse_args(args, s)
end

function main(args::Vector{String})
    if isempty(args)
        parse_commandline(["-h"])
        return nothing
    end
    arguments = parse_commandline(args)
    if arguments["verbose"]
        ENV["JULIA_DEBUG"] = "Main,JuliaCheck"
    end

    filter_rules(Set(arguments["rules"]))

    for in_file::String in arguments["infiles"]
        if !(isfile(in_file))
            @error ">> Error: cannot read '$in_file' as a file."
        else
            print("\n>> Processing file '")
            printstyled(in_file; color=:green)
            print("'...\n")
            Process.check(in_file; print_ast = arguments["ast"],
                                   print_llt = arguments["llt"])
        end
    end
    println()
end

if endswith(PROGRAM_FILE, "run_debugger.jl") || abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end

end
