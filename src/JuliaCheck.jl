module JuliaCheck

import JuliaSyntax as JS
using ArgParse: ArgParseSettings, project_version, @add_arg_table!, parse_args
using InteractiveUtils

include("LosslessTrees.jl")
include("Properties.jl"); import .Properties
include("Checks.jl"); import .Checks: filter_rules
include("Process.jl"); import .Process
include("Analysis.jl")

using .Analysis
 
Analysis.load_all_checks2()

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
        "--checks2"
            help = "Use checks from checks2 directory."
            action = :store_true
        "infiles"
            help = "One or more Julia files to check with available rules."
            nargs = '+'
            arg_type = String
            required = true
    end

    return parse_args(args, s)
end

function highlighting_violation_printer(violations)
    for v in violations
        Properties.report_violation(
            v.node;
            severity = severity(v.check),
            user_msg = v.msg,
            summary = synopsis(v.check),
            rule_id = id(v.check)
            )
    end
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

    rules_arg = Set(arguments["rules"])
    checks_to_run = map(c -> c(), subtypes(Analysis.Check))

    if arguments["checks2"]
        checks_to_run = filter(c -> id(c) in rules_arg, checks_to_run)
        if length(checks_to_run) >= 1
            @debug "Enabled rules:\n" * join(map(id, checks_to_run), "\n")
        else 
            @warn "No rules enabled"
        end
    else
        filter_rules(rules_arg)
    end

    for in_file::String in arguments["infiles"]
        if !(isfile(in_file))
            @error ">> Error: cannot read '$in_file' as a file."
        else
            print("\n>> Processing file '")
            printstyled(in_file; color=:green)
            print("'...\n")

            if arguments["checks2"]
                text::String = read(in_file, String)
                Analysis.run_analysis(text, checks_to_run; 
                    filename=in_file,
                    violationprinter = highlighting_violation_printer,
                    print_ast = arguments["ast"], 
                    print_llt = arguments["llt"])
            else
                Process.check(in_file; print_ast = arguments["ast"],
                              print_llt = arguments["llt"])
            end
        end
    end
    println()
end

if endswith(PROGRAM_FILE, "run_debugger.jl") || abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end

end
