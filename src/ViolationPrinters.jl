module ViolationPrinters

export highlighting_violation_printer

using ...Analysis
using ...Properties

function highlighting_violation_printer(violations)
    for v in violations
        Properties.report_violation(
            index = v.bufferrange.start,
            len = v.bufferrange.stop - v.bufferrange.start + 1,
            line = v.linepos[1],
            col = v.linepos[2],
            severity = severity(v.check),
            user_msg = v.msg,
            summary = synopsis(v.check),
            rule_id = id(v.check)
            )
    end
end

end # module ViolationPrinters
