module ViolationPrinters

export highlighting_violation_printer

using JuliaSyntax
using ...Analysis

function report_violation(sourcefile::SourceFile; index::Int, len::Int, line::Int, col::Int,
                            severity::Int, user_msg::String,
                            summary::String, rule_id::String)::Nothing
    printstyled("\n$(JuliaSyntax.filename(sourcefile))($line, $col):\n";
                underline=true)
    JuliaSyntax.highlight(stdout, sourcefile, index:index+len-1;
                 note=user_msg, notecolor=:yellow,
                 context_lines_after=0, context_lines_before=0)
    printstyled("\n$summary"; color=:cyan)
    printstyled("\nRule:"; underline=true)
    printstyled(" $rule_id. ")
    printstyled("Severity:"; underline=true)
    printstyled(" $severity\n")
end

function highlighting_violation_printer(sourcefile::SourceFile, violations::Vector{Violation})::Nothing
    append_period(s::String) = endswith(s, ".") ? s : s * "."
    for v in violations
        report_violation(
            sourcefile,
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

end # module ViolationPrinters
