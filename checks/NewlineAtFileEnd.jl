module NewlineAtFileEnd

using JuliaSyntax
using ...Properties: is_toplevel
using ...WhitespaceHelpers: get_line_range

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "newline-at-file-end"
Analysis.severity(::Check) = 7
Analysis.synopsis(::Check) = "Single newline at the end of file"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_toplevel, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    text = node.source.code
    if !endswith(text, r"[\r\n]")
        last_line_idx = length(node.source.line_starts) - 1
        range = get_line_range(last_line_idx, node.source)
        report_violation(ctxt, this, (last_line_idx, 0), range, "No newline found at end of file")
    end
    return nothing
end

end # module NewlineAtFileEnd
