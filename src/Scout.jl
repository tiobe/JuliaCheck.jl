module Scout

import JuliaSyntax: Kind, GreenNode, SyntaxNode, SourceFile, @K_str, @KSet_str,
    children, head, kind, numchildren, span, untokenize, JuliaSyntax as JS

include("JuliaCheck.jl"); import .JuliaCheck: main
using .JuliaCheck.Properties: SF, report_violation, _report_common

SINK = IOBuffer()

function JuliaCheck.Properties.report_violation(
        node::SyntaxNode; severity::Int, user_msg::String,
                          summary::String, rule_id::String
        )::Nothing
    line, column = JS.source_location(node)
    printstyled(SINK, "\n$(JS.filename(node))($line, $(column)):\n";
                underline=true)
    JS.highlight(SINK, node; note=user_msg, notecolor=:yellow,
                               context_lines_after=0, context_lines_before=0)
    _report_common(severity, rule_id, summary)
end
function JuliaCheck.Properties.report_violation(
        ; index::Int, len::Int, line::Int, col::Int,
          severity::Int, user_msg::String, summary::String, rule_id::String
        )::Nothing
    printstyled(SINK, "\n$(JS.filename(SF))($line, $col):\n";
                underline=true)
    JS.highlight(SINK, SF, index:index+len-1;
                 note=user_msg, notecolor=:yellow,
                 context_lines_after=0, context_lines_before=0)
    _report_common(severity, rule_id, summary)
end
function JuliaCheck.Properties._report_common(
        severity::Int, rule_id::String, summary::String)::Nothing
    printstyled(SINK, "\n$summary"; color=:cyan)
    printstyled(SINK, "\nRule:"; underline=true)
    printstyled(SINK, " $rule_id. ")
    printstyled(SINK, "Severity:"; underline=true)
    printstyled(SINK, " $severity\n")
end


if endswith(PROGRAM_FILE, "run_debugger.jl") || abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end

end # module Scout
