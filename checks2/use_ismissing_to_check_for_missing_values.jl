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
        apply_to_operands(node, n -> checkOperand(this, ctxt, n))
    end)
end

function checkOperand(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    missing_type = extract_missing_type(node)
    if missing_type !== nothing
        report_violation(ctxt, this, node, synopsis(this))
    end
end

function extract_missing_type(node::SyntaxNode)::Union{String, Nothing}
    if kind(node) == K"." && length(children(node)) >= 2
        # For qualified names like Base.Inf, return just the Inf part
        node = last(children(node))
    end

    if kind(node) == K"Identifier" && string(node) ∈ ("Missing", "missing")
        return string(node)
    end

    return nothing
end

end # module UseIsmissingToCheckForMissingValues
