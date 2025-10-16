module HighlightingViolationPrinter

import ...Analysis: Violation, severity, id, synopsis
import ..ViolationPrinterInterface: shorthand, requiresfile, print_violations; using ..ViolationPrinterInterface
import JuliaSyntax: SourceFile, JuliaSyntax as JS

struct ViolationPrinter<:ViolationPrinterInterface.ViolationPrinter end
shorthand(::ViolationPrinter) = "highlighting"
requiresfile(::ViolationPrinter) = false

function print_violations(this::ViolationPrinter, outputfile::String, violations::Vector{Violation})::Nothing
    append_period(s::String) = endswith(s, ".") ? s : s * "."
    for v in violations
        _report_violation(
            v.sourcefile,
            index = v.bufferrange.start,
            len = v.bufferrange.stop - v.bufferrange.start + 1,
            line = v.linepos[1],
            col = v.linepos[2],
            severity = severity(v.check),
            user_msg = append_period(v.msg),
            summary = append_period(synopsis(v.check)), # Do we want to add a dot after each synopsis?
            rule_id = id(v.check)
            )
    end
    return nothing
end

function _report_violation(sourcefile::SourceFile; index::Int, len::Int, line::Int, col::Int,
                            severity::Int, user_msg::String,
                            summary::String, rule_id::String)::Nothing
    printstyled("\n$(JS.filename(sourcefile))($line, $col):\n";
                underline=true)
    JS.highlight(stdout, sourcefile, index:index+len-1;
                 note=user_msg, notecolor=:yellow,
                 context_lines_after=0, context_lines_before=0)
    printstyled("\n$summary"; color=:cyan)
    printstyled("\nRule:"; underline=true)
    printstyled(" $rule_id. ")
    printstyled("Severity:"; underline=true)
    printstyled(" $severity\n")
end

end # module HighlightingViolationPrinter
