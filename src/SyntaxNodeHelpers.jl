module SyntaxNodeHelpers

export ancestors, is_scope_construct, apply_to_operands

using JuliaSyntax: SyntaxNode, kind, numchildren, children, source_location, is_operator,
    is_infix_op_call, is_prefix_op_call
import JuliaSyntax: @KSet_str

"Returns list of ancestors for given node, excluding self, ordered by increasing distance."
function ancestors(node::SyntaxNode)::Vector{SyntaxNode}
    list=Vector{SyntaxNode}()
    n = node.parent
    while n !== nothing
        push!(list, n)
        n = n.parent
    end
    return list
end

"Applies function to operands of given operator node."
function apply_to_operands(node::SyntaxNode, func::Function)
    if numchildren(node) != 3
        @debug "Skipping comparison with a number of children != 3 at $(source_location(node))" node
    elseif is_infix_op_call(node)
        lhs, _, rhs = children(node)
        func(lhs)
        func(rhs)
    elseif is_prefix_op_call(node)
        _, op = children(node)
        func(op)
    end
end


"""
Whether this node introduces a new scope.
See https://docs.julialang.org/en/v1/manual/variables-and-scoping/
"""
function is_scope_construct(node::SyntaxNode)::Bool
    return kind(node) in KSet"module baremodule struct for while try macro function"
end

end # module SyntaxNodeHelpers
