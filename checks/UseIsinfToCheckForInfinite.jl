module UseIsinfToCheckForInfinite

using ...Properties: is_eq_neq_comparison
using ...SyntaxNodeHelpers

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "use-isinf-to-check-for-infinite"
severity(::Check) = 3
synopsis(::Check) = "Use isinf to check for infinite values"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_eq_neq_comparison, node -> begin
        apply_to_operands(node, node -> begin
            if extract_special_value(node) ∈ SyntaxNodeHelpers.INF_VALUES
                report_violation(ctxt, this, node, synopsis(this))
            end
        end)
    end)
end

end # module UseIsinfToCheckForInfinite
