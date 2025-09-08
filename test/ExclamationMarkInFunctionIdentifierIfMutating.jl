
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
function reset_vector!(vec::Vector{T})::Nothing where T <: Real  # bang added
    vec .= zero(T) # or zero(eltype(vec))
    return nothing
end