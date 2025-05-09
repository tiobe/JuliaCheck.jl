get_specific_numbers()::Vector{Int64} = sort([abs((rand(Int64)) % 5) for i::Int64 in range(1, 5)])

# Good style:
function get_specific_numbers()::Vector{Int64}
    vec = rand(Int64, 5)
    # Get five random numbers between typemin(Int64) and typemax(Int64)

    vec = sort([abs(element % 5) for element in vec])
    # Of each element, take the absolute value, modulo 5, and sort

    return vec
end

expr_depth(node) = haschildren(node) ?
    (1 + max(expr_depth.(children(node)))) : 0
