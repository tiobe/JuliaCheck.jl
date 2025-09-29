module OneExpressionPerLine

using JuliaSyntax: first_byte, last_byte, is_prefix_call, is_prefix_op_call
using ...Properties: is_toplevel

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "one-expression-per-line"
severity(::Check) = 7
synopsis(::Check) = "The number of expressions per line is limited to one."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_type_assertion_or_constraint, n -> check(this, ctxt, n))
end

function is_type_assertion_or_constraint(node)::Bool
    return kind(node) in KSet":: <: >:"
end

function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)

end

end # module OneExpressionPerLine
