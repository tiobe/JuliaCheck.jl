module ViolationPrinters

import JSON3

export highlighting_violation_printer, report_violation


using JuliaSyntax
using ..Analysis

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

function highlighting_violation_printer(outputfile::String, sourcefile::SourceFile, violations::Vector{Violation})::Nothing
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

Base.@kwdef struct ViolationOutput
    line_start::Int64
    column_start::Int64
    line_end::Int64
    column_end::Int64
    julia_source_code_filename::String
    severity::Int64
    rule_id::String
    summary::String
    user_message::String
    url::String
end

function json_violation_printer(outputfile::String, sourcefile::SourceFile, violations::Vector{Violation})::Nothing
    append_period(s::String) = endswith(s, ".") ? s : s * "."
    output_violations = []
    for v in violations
        l_end, c_end = source_location(sourcefile, v.bufferrange.stop)
        push!(output_violations, ViolationOutput(
            line_start = v.linepos[1],
            column_start = v.linepos[2],
            line_end = l_end,
            column_end = c_end,
            julia_source_code_filename = JuliaSyntax.filename(sourcefile),
            severity = severity(v.check),
            rule_id = id(v.check),
            user_message = append_period(v.msg),
            summary = append_period(synopsis(v.check)),
            url = ""
        ))
    end
    json_string::String = JSON3.write(output_violations)
    io = open(outputfile, "w")
    JSON3.pretty(io, json_string)
    close(io)
    return nothing
end

end # module ViolationPrinters
