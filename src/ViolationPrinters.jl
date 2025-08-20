module ViolationPrinters

export highlighting_violation_printer

using JuliaSyntax: SyntaxNode, first_byte, last_byte
using ...Analysis
using ...Properties

function highlighting_violation_printer(violations)
    for v in violations
        start = first_byte(v.node)
        len = last_byte(v.node) - start + 1
        if v.offsetspan !== nothing
            start += v.offsetspan[1]
            len = v.offsetspan[2]
        end
        Properties.report_violation(
            index = start,
            len = len,
            line = v.line,
            col = v.column,
            severity = severity(v.check),
            user_msg = v.msg,
            summary = synopsis(v.check),
            rule_id = id(v.check)
            )
    end
end

end # module ViolationPrinters
