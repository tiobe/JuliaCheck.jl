# Bad:
num_vector = Real[1.0, 2, 3] # Type will be Vector{Real}. Real is abstract.
another_vector = Array{Number}[]
a_set = Set{AbstractFloat}[1.0, 2, 3]

# Good:
num_vector = [1.0, 2, 3] # Type will be Vector{Float64}. Float64 is concrete.
num_vector = Int[1, 2, 3] # If Int is preferred