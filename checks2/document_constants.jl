module DocumentConstants

using ...Properties: find_lhs_of_kind, haschildren, is_constant

include("_common.jl")

struct Check <: Analysis.Check end
id(::Check) = "document-constants"
severity(::Check) = 7
synopsis(::Check) = "Constants must have a docstring"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_constant, n -> check(this, ctxt, n))
end

function check(this::Check, ctxt::AnalysisContext, const_node::SyntaxNode)
    if kind(const_node) == K"global"
        if haschildren(const_node)
            const_node = children(const_node)[1]
        else
            @debug "A global node without children:" const_node
            return nothing
        end
    end
    @assert kind(const_node) == K"const" "Expected a [const] const_node, got $(kind(const_node))."
    if haschildren(const_node) && kind(children(const_node)[1]) == K"="
        # This is a constant value declaration.
        assignment = children(const_node)[1]
        if haschildren(assignment)
            if kind(const_node.parent) != K"doc"
                const_id = find_lhs_of_kind(K"Identifier", const_node)
                report_violation(ctxt, this, const_node,
                        "Const value $(string(const_id)) has no docstring."
                        )
            end
        else
            @debug "An assignment without children:" assignment
        end
    end
end

end
