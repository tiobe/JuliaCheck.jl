module SimpleViolationPrinter

using ...Analysis: Violation, severity, id
using ..Output

struct ViolationPrinter<:Output.ViolationPrinter end
Output.shorthand(::ViolationPrinter) = "simple"
Output.requiresfile(::ViolationPrinter) = false

function Output.print_violations(this::ViolationPrinter, outputfile::String, violations::Vector{Violation})::Nothing
    if length(violations) == 0
        println("No violations found.")
    else
        println("Found $(length(violations)) violations:")
        idx = 1
        for v in violations
            println("$(idx). Check: $(id(v.check)), Line/col: $(v.linepos), Severity: $(severity(v.check)), Message: $(v.msg)")
            idx += 1
        end
    end
    return nothing
end

end # module SimpleViolationPrinter
