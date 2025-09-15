module SyntaxNodeHelpers

export ancestors, is_scope_construct, apply_to_operands, extract_special_value, find_node_at_position
export SpecialValue

using JuliaSyntax: SyntaxNode, kind, numchildren, children, source_location, is_operator,
    is_infix_op_call, is_prefix_op_call, byte_range
import JuliaSyntax: @K_str, @KSet_str

"Returns list of ancestors for given node, excluding self, ordered by increasing distance."
function ancestors(node::SyntaxNode; include_self::Bool = false)::Vector{SyntaxNode}
    list = Vector{SyntaxNode}()
    if include_self
        push!(list, node)
    end
    n = node.parent
    while !isnothing(n)
        push!(list, n)
        n = n.parent
    end
    return list
end

"Applies function to operands of given operator node."
function apply_to_operands(node::SyntaxNode, func::Function)::Nothing
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
    return nothing
end

const INF_VALUES = Set(["Inf", "Inf16", "Inf32", "Inf64"])
const NAN_VALUES = Set(["NaN", "NaN16", "NaN32", "NaN64"])
const MISSING_VALUES = Set(["missing", "Missing"])
const NOTHING_VALUES = Set(["nothing", "Nothing"])
const SPECIAL_VALUES = union(INF_VALUES, NAN_VALUES, MISSING_VALUES, NOTHING_VALUES)

"""
Extract special value from given expression.
Special values are `Inf`, `NaN`, `nothing`, `missing`, and variants (Inf16, NaN64, etc).

Example input -> output:
    ```
    Base.Inf32 -> Inf32
    Inf64 -> Inf64
    ````

See https://docs.julialang.org/en/v1/manual/integers-and-floating-point-numbers/#Special-floating-point-values
"""
function extract_special_value(expr::SyntaxNode)::Union{String, Nothing}
    sign = ""
    if kind(expr) == K"call" && numchildren(expr) > 1
        first, second = children(expr)[1:2]
        if kind(first) == K"Identifier" && string(first) ∈ ("-", "+")
            expr = second
        end
    end

    if kind(expr) == K"." && length(children(expr)) >= 2
        # For qualified names like Base.Inf, return just the Inf part
        expr = last(children(expr))
    end

    if kind(expr) == K"Identifier"
        value = string(expr)
        if value ∈ SPECIAL_VALUES
            return value
        end
    end

    return nothing
end


"""
Finds deepest node containing the given `pos`.
If there is no `SyntaxNode` that contains the position, the `toplevel` node is returned.
"""
function find_node_at_position(node::SyntaxNode, pos::Integer)::Union{SyntaxNode,Nothing}
    # Check if the current node contains the position
    if ! (pos in byte_range(node))
        return nothing
    end

    # Search through children to find the most specific node
    for child in something(children(node), [])
        found_child = find_node_at_position(child, pos)
        if found_child !== nothing
            return found_child
        end
    end

    # If no child matches, this is the most specific node
    return node
end

"""
Whether this node introduces a new scope.
See https://docs.julialang.org/en/v1/manual/variables-and-scoping/
"""
function is_scope_construct(node::SyntaxNode)::Bool
    return kind(node) in KSet"module baremodule struct for while try macro function"
end

end # module SyntaxNodeHelpers
