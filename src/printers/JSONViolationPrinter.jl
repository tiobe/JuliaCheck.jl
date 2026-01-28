module JSONViolationPrinter

using ...Analysis: Violation, severity, id, synopsis
using JSON3
using JuliaSyntax: filename, source_location
using ..Output

struct ViolationPrinter<:Output.ViolationPrinter end
Output.shorthand(::ViolationPrinter) = "json"
Output.requiresfile(::ViolationPrinter) = true

Base.@kwdef struct ViolationOutput
    line_start::Int64
    column_start::Int64
    line_end::Int64
    column_end::Int64
    filename::String
    severity::Int64
    rule_id::String
    summary::String
    user_message::String
    url::String
end

function Output.print_violations(this::ViolationPrinter, outputfile::String, violations::Vector{Violation})::Nothing
    append_period(s::String) = endswith(s, ".") ? s : s * "."
    output_violations = Vector{ViolationOutput}()
    for v in violations
        l_end, c_end = source_location(v.sourcefile, v.bufferrange.stop)
        push!(output_violations, ViolationOutput(
            line_start = v.linepos[1],
            column_start = v.linepos[2],
            line_end = l_end,
            column_end = c_end + 1,
            filename = filename(v.sourcefile),
            severity = severity(v.check),
            rule_id = id(v.check),
            user_message = append_period(v.msg),
            summary = append_period(synopsis(v.check)),
            url = ""
        ))
    end
    io = open(outputfile, "w")
    JSON3.pretty(io, output_violations)
    close(io)
    return nothing
end

end # module JSONViolationPrinter
