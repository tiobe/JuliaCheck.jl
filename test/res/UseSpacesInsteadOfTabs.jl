function get_specific_numbers()::Vector{Int64}
	vec = rand(Int64, 5)
    # Get five random numbers between typemin(Int64) and typemax(Int64)

    vec = sort([abs(element % 5) for element in vec])
	# Of each element, take the absolute value, modulo 5, and sort

    if isnothing(vec)
    	println("Bad vector.	String are off-limits.")
    end
	
    return vec
end

fck(;) = π
