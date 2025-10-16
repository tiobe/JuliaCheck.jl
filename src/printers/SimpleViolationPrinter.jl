module SimpleViolationPrinter

import ...Analysis: Violation, severity, id
import ..ViolationPrinterInterface: shorthand, requiresfile, print_violations; using ..ViolationPrinterInterface
import JuliaSyntax: SourceFile

struct ViolationPrinter<:ViolationPrinterInterface.ViolationPrinter end
shorthand(::ViolationPrinter) = "simple"
requiresfile(::ViolationPrinter) = false

function print_violations(this::ViolationPrinter, outputfile::String, violations::Vector{Violation})::Nothing
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
