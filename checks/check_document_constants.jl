module DocumentConstants

using JuliaSyntax: SyntaxNode, @K_str, children, haschildren, kind

using ...Properties: report_violation

export check

function check(const_node::SyntaxNode)
    @assert kind(const_node) == K"const" "Expected a [const] const_node, got $(kind(const_node))."
    if haschildren(const_node) && kind(children(const_node)[1]) == K"="
        # This is a constant value declaration. Is it a real number?
        assignment = children(const_node)[1]
        if haschildren(assignment) && kind(children(assignment)[2]) == K"Float"
            # Yes, it is a real number. Then, it must have a docstring with it.
            if kind(const_node.parent) != K"doc"
                report_violation(const_node; severity=7,
                        rule_id="asml-xxxx-document-constants",
                        user_msg="Const value $const_node has no docstring.",
                        summary="Constants must have a docstring.")
            end
        else
            @debug "An assignment without children:" assignment
        end
    end
end

end
