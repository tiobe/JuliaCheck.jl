module DocumentConstants

using ...Properties: find_lhs_of_kind, haschildren, is_constant
using ...SyntaxNodeHelpers: find_descendants

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "document-constants"
severity(::Check) = 7
synopsis(::Check) = "Constants must have a docstring"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"const", n -> check(this, ctxt, n))
end

function check(this::Check, ctxt::AnalysisContext, const_node::SyntaxNode)
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
end

end
