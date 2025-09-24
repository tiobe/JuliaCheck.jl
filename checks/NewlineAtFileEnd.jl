module NewlineAtFileEnd

using JuliaSyntax
using ...Properties: is_toplevel
using ...WhitespaceHelpers: get_line_range

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "newline-at-file-end"
severity(::Check) = 7
synopsis(::Check) = "Single newline at the end of file"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_toplevel, n -> _check(this, ctxt, n))
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    text = node.source.code
    if !endswith(text, r"[\r\n]")
        last_line_idx = length(node.source.line_starts) - 1
        range = get_line_range(last_line_idx, node.source)
        report_violation(ctxt, this, (last_line_idx, 0), range, "No newline found at end of file")
    end
end

end # module NewlineAtFileEnd
