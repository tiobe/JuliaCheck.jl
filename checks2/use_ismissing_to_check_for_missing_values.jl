module UseIsmissingToCheckForMissingValues

include("_common.jl")

using ...Properties: is_eq_neq_comparison
using ...SyntaxNodeHelpers

struct Check <: Analysis.Check end
id(::Check) = "use-ismissing-to-check-for-missing-values"
severity(::Check) = 3
synopsis(::Check) = "Use ismissing to check for missing values"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_eq_neq_comparison, node -> begin
        apply_to_operands(node, node -> begin
            if extract_special_value(node) ∈ SyntaxNodeHelpers.MISSING_VALUES
                report_violation(ctxt, this, node, synopsis(this))
            end
        end)
    end)
end

end # module UseIsmissingToCheckForMissingValues
