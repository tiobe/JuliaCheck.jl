module UseIsinfToCheckForInfinite

include("_common.jl")

using ...Properties: is_eq_neq_comparison
using ...SyntaxNodeHelpers

struct Check <: Analysis.Check end
id(::Check) = "use-isinf-to-check-for-infinite"
severity(::Check) = 3
synopsis(::Check) = "Use isinf to check for infinite values"

const INF_VALUES = Set(["Inf", "Inf16", "Inf32", "Inf64"])

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_eq_neq_comparison, node -> begin
        apply_to_operands(node, n -> checkExpr(this, ctxt, n))
    end)
end

function checkExpr(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    inf_type = extract_special_constant(node, INF_VALUES)
    if inf_type !== nothing
        report_violation(ctxt, this, node, synopsis(this))
    end
end


end # module UseIsinfToCheckForInfinite
