module UseIsmissingToCheckForMissingValues

using ...Properties: is_eq_neq_comparison
using ...SyntaxNodeHelpers

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "use-ismissing-to-check-for-missing-values"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Use ismissing to check for missing values"

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_eq_neq_comparison, node -> begin
        apply_to_operands(node, node -> begin
            if extract_special_value(node) ∈ SyntaxNodeHelpers.MISSING_VALUES
                report_violation(ctxt, this, node, synopsis(this))
            end
        end)
    end)
end

end # module UseIsmissingToCheckForMissingValues
