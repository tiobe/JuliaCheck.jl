module DocumentConstants

using JuliaSyntax: SyntaxNode, @K_str, children, kind

using ...Properties: find_first_of_kind, haschildren, report_violation

RULE_ID = "document-constants"
USER_MSG = "Const value has no docstring."
SUMMARY = "Constants must have a docstring."
SEVERITY = 7

function check(const_node::SyntaxNode)
    @assert kind(const_node) == K"const" "Expected a [const] const_node, got $(kind(const_node))."
    if haschildren(const_node) && kind(children(const_node)[1]) == K"="
        # This is a constant value declaration.
        assignment = children(const_node)[1]
        if haschildren(assignment)
            if kind(const_node.parent) != K"doc"
                const_id = find_first_of_kind(K"Identifier", const_node)
                report_violation(const_node;
                        severity = SEVERITY, rule_id = RULE_ID,
                        user_msg = "Const value $(string(const_id)) has no docstring.", # TODO #36595
                        summary = SUMMARY)
            end
        else
            @debug "An assignment without children:" assignment
        end
    end
end

end
