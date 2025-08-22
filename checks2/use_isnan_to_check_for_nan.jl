module UseIsnanToCheckForNan

include("_common.jl")

using ...Properties: is_eq_neq_comparison
using ...SyntaxNodeHelpers

struct Check <: Analysis.Check end
id(::Check) = "use-isnan-to-check-for-nan"
severity(::Check) = 3
synopsis(::Check) = "Use isnan to check for not-a-number values"

const NAN_TYPES = Set(["NaN", "NaN16", "NaN32", "NaN64"])

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_eq_neq_comparison, node -> begin
        apply_to_operands(node, n -> checkOperand(this, ctxt, n))
    end)
end

function checkOperand(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    inf_type = extract_special_constant(node, NAN_TYPES)
    if inf_type !== nothing
        report_violation(ctxt, this, node, synopsis(this))
    end
end

end # module UseIsnanToCheckForNan
