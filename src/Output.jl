module Output

export ViolationPrinter, shorthand, requiresfile, print_violations

import ..Analysis: Violation

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

end # module Output
