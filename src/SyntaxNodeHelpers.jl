module SyntaxNodeHelpers

export ancestors, is_scope_construct, apply_to_operands, extract_special_constant

using JuliaSyntax: SyntaxNode, kind, numchildren, children, source_location, is_operator,
    is_infix_op_call, is_prefix_op_call
import JuliaSyntax: @K_str, @KSet_str

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
Extract special (i.e. Inf or Nan) constant value from given expression,
but only if the constant occurs in `allowed_set`.

See https://docs.julialang.org/en/v1/manual/integers-and-floating-point-numbers/#Special-floating-point-values
"""
function extract_special_constant(expr::SyntaxNode, allowed_set::Set{String})::Union{String, Nothing}
    sign = ""
    if kind(expr) == K"call" && numchildren(expr) > 1
        first, second = children(expr)[1:2]
        if kind(first) == K"Identifier" && string(first) ∈ ("-", "+")
            if string(first) == "-" 
                sign = "-" 
            end
            expr = second
        end
    end

    if kind(expr) == K"." && length(children(expr)) >= 2
        # For qualified names like Base.Inf, return just the Inf part
        expr = last(children(expr))
    end

    if kind(expr) == K"Identifier"
        value = string(expr)
        if value ∈ allowed_set
            return sign * value
        end
    end

    return nothing
end



"""
Whether this node introduces a new scope.
See https://docs.julialang.org/en/v1/manual/variables-and-scoping/
"""
function is_scope_construct(node::SyntaxNode)::Bool
    return kind(node) in KSet"module baremodule struct for while try macro function"
end

end # module SyntaxNodeHelpers
