module UseIsinfToCheckForInfinite

using ...Properties: is_eq_neq_comparison
using ...SyntaxNodeHelpers

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "use-isinf-to-check-for-infinite"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Use isinf to check for infinite values"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_eq_neq_comparison, node -> begin
        apply_to_operands(node, node -> begin
            if extract_special_value(node) ∈ SyntaxNodeHelpers.INF_VALUES
                report_violation(ctxt, this, node, synopsis(this))
            end
        end)
    end)
    return nothing
end

end # module UseIsinfToCheckForInfinite
