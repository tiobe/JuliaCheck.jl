
# Bad
function reset_vector(vec::Vector{T})::Nothing where T <: Real  # bang omitted
    vec .= zero(T) # or zero(eltype(vec))
    return nothing
end

function field_changer(some_object::Thingie)
    some_object.field = 1
end

function array_changer(some_array::Vector{Int64})
    some_array[2] = 12
end

function array_changer_two(some_array::Vector{Int64})
    push!(some_array, 123)
end

function array_changer_three(some_array::Vector{Int64}, another::Int64)
    push!(some_array, another)
end

# Good
function set_from_array(a::Vector{Int64})::Int64
    b = a[1]
    return b
end

function reset_vector!(vec::Vector{T})::Nothing where T <: Real  # bang added
    vec .= zero(T) # or zero(eltype(vec))
    return nothing
end

function _node_is_in_scope(node::SyntaxNode, scp::Scope)::Bool
    symbol_id = _get_symbol_id(node)
    if haskey(scp, symbol_id)
        return node ∈ scp[symbol_id].all_nodes
    end
    return false
end

function _find_greenleaf(leaves::Vector{GreenLeaf}, pos::Int)::Union{GreenLeaf, Nothing}
    low = 1
    high = length(leaves)
    while low <= high
        mid_idx = low + (high - low) ÷ 2
        mid_leaf = leaves[mid_idx]
        mid_range = mid_leaf.range

        if pos in mid_range
            return mid_leaf
        elseif pos < mid_range.start
            high = mid_idx - 1
        else # pos > mid_range.stop
            low = mid_idx + 1
        end
    end
    return nothing
end