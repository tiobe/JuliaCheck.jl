module Output

export ViolationPrinter, get_available_printers, shorthand, requiresfile, print_violations,
        select_violation_printer, parse_output_file_arg

import ..Analysis: Violation
import InteractiveUtils: subtypes

"The abstract base type for all violation printers."
abstract type ViolationPrinter end
shorthand(::ViolationPrinter) = error("shorthand() not implemented for this violation printer")
requiresfile(::ViolationPrinter) = error("requiresfile() not implemented for this violation printer")
print_violations(::ViolationPrinter, outputfile::String, violations::Vector{Violation}) = error("print_violations() not implemented for this violation printer")

"Load all violation printers in printers directory."
function discover_violation_printers()::Nothing
    violation_printers_path = joinpath(@__DIR__, "printers")
    include_dependency(violation_printers_path) # Mark directory contents as precompilation dependency
    for file in filter(f -> endswith(f, ".jl"), readdir(violation_printers_path, join=true))
        try
            include(file)
            include_dependency(file)
        catch exception
            @warn "Failed to load violation printer '$(basename(file))':" exception
        end
    end
    return nothing
end

function select_violation_printer(output_arg::String)::ViolationPrinter
    for printer in get_available_printers()
        if output_arg == shorthand(printer)
            return printer
        end
    end
    throw("Unknown violation printer type: $output_arg")
    return nothing
end

function parse_output_file_arg(violation_printer::ViolationPrinter, output_file_arg::Union{String, Nothing})::String
    if isnothing(output_file_arg)
        if requiresfile(violation_printer)
            shorthand_msg = shorthand(violation_printer)
            throw("Error: $(shorthand_msg) output requires an output file.")
        end
        return ""
    end
    io = open(output_file_arg, "w")
    if ! iswritable(io)
        throw("Error: Cannot write to $(output_file_arg).")
    end
    close(io)
    return output_file_arg
end

get_available_printers() = map(p -> p(), subtypes(ViolationPrinter))

end # module Output
