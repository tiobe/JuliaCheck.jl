
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