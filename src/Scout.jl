module Scout

import JuliaSyntax: Kind, GreenNode, SyntaxNode, SourceFile, @K_str, @KSet_str,
    children, head, kind, numchildren, span, untokenize, JuliaSyntax as JS

include("JuliaCheck.jl"); import .JuliaCheck: main
using .JuliaCheck.Properties: SF, report_violation, _report_common
using .JuliaCheck.LosslessTrees: LosslessNode

function JuliaCheck.Properties.report_violation(
        node::SyntaxNode; severity::Int, user_msg::String,
                          summary::String, rule_id::String
        )::Nothing
    return nothing
end
function JuliaCheck.Properties.report_violation(
        node::LosslessNode; delta::Int=0,
                          severity::Int, user_msg::String,
                          summary::String, rule_id::String)::Nothing
    return nothing
end
function JuliaCheck.Properties.report_violation(
        ; index::Int, len::Int, line::Int, col::Int,
          severity::Int, user_msg::String, summary::String, rule_id::String
        )::Nothing
    return nothing
end

if endswith(PROGRAM_FILE, "run_debugger.jl") || abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end

end # module Scout
