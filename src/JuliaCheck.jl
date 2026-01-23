module JuliaCheck

using JuliaSyntax: first_byte, last_byte, SourceFile
using ArgParse: ArgParseSettings, project_version, @add_arg_table!, parse_args
using InteractiveUtils

include("Properties.jl"); import .Properties
include("TypeHelpers.jl"); import .TypeHelpers
include("SyntaxNodeHelpers.jl")
include("SymbolTable.jl")
include("Analysis.jl")
include("Output.jl")
include("MutatingFunctionsHelpers.jl")
include("WhitespaceHelpers.jl"); import .WhitespaceHelpers
include("CommentHelpers.jl"); import .CommentHelpers

using .Analysis
using .Output

export main

Analysis.discover_checks()
Output.discover_violation_printers()

function _parse_commandline(args::Vector{String})
    s = ArgParseSettings(
            description = "Code checker for Julia programming language.",
            epilog = """
            If you '--enable' a list of rules, separate it from the list of input files with '--'.
            """,
            add_version = true, version = project_version(joinpath(@__DIR__, "..", "Project.toml")))

    shorthand_ids = map(shorthand, get_available_printers())
    printer_string = join(shorthand_ids, ", ")
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
        "--output"
            help = "Select output type. Allowed types: $(printer_string)."
            arg_type = String
            default = "highlighting"
        "--outputfile"
            help = "Write output to the given file. If left empty, this will write to command line."
            arg_type = String
        "infiles"
            help = "One or more Julia files or directories to check with available rules."
            nargs = '+'
            arg_type = String
            required = true
    end

    return parse_args(args, s)
end

function main(args::Vector{String})::Nothing
    if isempty(args)
        _parse_commandline(["-h"])
        return nothing
    end
    arguments = _parse_commandline(args)

    # arguments can be empty in the case you only pass -version:
    # terminate early if that is the case
    if isnothing(arguments)
        return nothing
    end

    if arguments["verbose"]
        ENV["JULIA_DEBUG"] = "Main,JuliaCheck"
    end

    violation_printer = select_violation_printer(arguments["output"])
    output_file_arg = parse_output_file_arg(violation_printer, arguments["outputfile"])

    rules_arg = Set(arguments["rules"])
    available_checks = map(c -> c(), subtypes(Analysis.Check))
    intersect = setdiff(rules_arg, map(id, available_checks))
    if !isempty(intersect)
        throw("Unknown rules: $intersect")
    end
    checks_to_run = filter(c -> isempty(rules_arg) || id(c) in rules_arg, available_checks)
    violations::Vector{Violation} = []
    for in_file::String in _get_files_to_analyze(arguments["infiles"])
        if !(isfile(in_file))
            @error ">> Error: cannot read '$in_file' as a file."
        else
            print("\n>> Processing file '")
            printstyled(in_file; color=:green)
            print("'...\n")

            sourcefile::SourceFile = SourceFile(; filename=in_file)

            # Reinstantiate Checks to clear any variables they might have
            fresh_checks::Vector{Check} = map(type -> typeof(type)(), checks_to_run)

            new_violations = Analysis.run_analysis(sourcefile, fresh_checks;
                print_ast=arguments["ast"],
                print_llt=arguments["llt"])
            append!(violations, new_violations)
        end
    end
    print_violations(violation_printer, output_file_arg, violations)
    println()
    return nothing
end

function _has_julia_ext(file_arg::String)::Bool
    return lowercase(splitext(file_arg)[end]) == ".jl"
end

function _get_files_to_analyze(file_arg::Vector{String})::Vector{String}
    file_set = []
    for element in file_arg
        if isfile(element) && _has_julia_ext(element)
            push!(file_set, element)
        elseif isdir(element)
            for (root, _, files) in walkdir(element)
                for file in files
                    if _has_julia_ext(file)
                        push!(file_set, abspath(joinpath(root, file)))
                    end
                end
            end
        else
            error("No Julia file found at $element")
        end
    end
    return file_set
end

if endswith(PROGRAM_FILE, "run_debugger.jl") || abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end

end # module JuliaCheck
