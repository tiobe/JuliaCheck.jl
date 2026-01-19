
# Bad
function reset_vectors!(vec1::Vector{T}, vec2::Vector{T})::Nothing where T <: Real  # bang omitted
    vec1 .= zero(T)
    vec2 .= zero(T)
    return nothing
end

function all_the_changes!(a, b, c)
    a[1] = 1
    b[2] = 2
    c[3] = 3
end

function keyword_arguments(; a::Vector{Int64}, b::Vector{Int64})
    a[1] = 1
    b[2] = 2
end

# Good
function reset_vector!(vec1::Vector{T}, vec2::Vector{T})::Nothing where T <: Real  # bang omitted
    vec1 .= zero(T)
    return nothing
end

function _check_on_boolean(a::Int64, b::Bool)::Int64
    if a > 10 && !b
        return 64
    end
    return a
end

function _check_on_another_boolean(a::Int64, b::Bool)::Int64
    if a >= 5 && ! b
        return 32
    end
    return a
end

function add_child_element!(a::Vector{Int64}, b::Int64, c::Int64)::Nothing
    push!(a, b)
    push!(a, c)
    return nothing
end

add_child_element!(_, _, _::Nothing)::Nothing = nothing

add_child_element!(__, __, __::Nothing)::Nothing = nothing

function first_add_without_override!(_, _, _::Nothing)::Nothing
    return nothing
end

second_add_without_override!(_, _, _::Nothing)::Nothing = nothing

third_add_without_override!(a, b, c::Nothing)::Nothing = nothing

one_more(_, a::Nothing)::Nothing = nothing

two_more(b, _::Nothing)::Nothing = nothing
