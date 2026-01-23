module DocumentConstants

using ...Properties: find_lhs_of_kind, haschildren, is_constant
using ...SyntaxNodeHelpers: find_descendants

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "document-constants"
Analysis.severity(::Check) = 7
Analysis.synopsis(::Check) = "Constants must have a docstring"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, n -> kind(n) == K"const", n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, const_node::SyntaxNode)::Nothing
    @assert kind(const_node) == K"const" "Expected a [const] const_node, got $(kind(const_node))."

    if kind(const_node.parent) == K"doc"
        return nothing # Nothing to report: there is a docstring already
    end

    # Find first (typically only) assignment underneath [const] node
    assignment = first(find_descendants(n -> kind(n) == K"=", const_node, true))
    if ! isnothing(assignment) && length(children(assignment)) >= 2
        rhs = children(assignment)[2]
        if kind(rhs) != K"curly" # RM-37765: ignore Union and other parameterized type
            const_id = find_lhs_of_kind(K"Identifier", const_node)
            report_violation(ctxt, this, const_node,
                    "Const value '$(string(const_id))' has no docstring"
                    )
        end
    end
    return nothing
end

end # module DocumentConstants
