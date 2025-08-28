module ViolationPrinters

export highlighting_violation_printer

using ...Analysis
using ...Properties

function highlighting_violation_printer(violations)::Nothing
    append_period(s::String) = endswith(s, ".") ? s : s * "."
    for v in violations
        Properties.report_violation(
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
