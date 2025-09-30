module OneExpressionPerLine

using JuliaSyntax: has_flags, JuliaSyntax as JS
using ...Properties: is_toplevel

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "one-expression-per-line"
severity(::Check) = 7
synopsis(::Check) = "The number of expressions per line is limited to one."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, _is_toplevel_semicolon, n -> check(this, ctxt, n))
end

function _is_toplevel_semicolon(node)::Bool
    return is_toplevel(node) && has_flags(node, JS.TOPLEVEL_SEMICOLONS_FLAG) 
end

function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    report_violation(ctxt, this, node, "Do not concatenate statements with a semicolon.")
end

end # module OneExpressionPerLine
