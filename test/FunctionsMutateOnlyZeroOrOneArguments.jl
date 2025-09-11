
# Bad
function reset_vectors!(vec1::Vector{T}, vec2::Vector{T})::Nothing where T <: Real  # bang omitted
    vec1 .= zero(T)
    vec2 .= zero(T)
    return nothing
end

# Good
function reset_vector!(vec1::Vector{T}, vec2::Vector{T})::Nothing where T <: Real  # bang omitted
    vec1 .= zero(T)
    return nothing
end
