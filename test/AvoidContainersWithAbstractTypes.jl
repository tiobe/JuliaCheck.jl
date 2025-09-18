# Bad:
num_vector = Real[1.0, 2, 3] # Type will be Vector{Real}. Real is abstract.
another_vector = Array{Number}[]
a_set = Set{AbstractFloat}([1.0, 2, 3])
double_array = Array{Array{Number}}
triple_array = Array{Array{Array{Number}}}
const POWERS_OF_WRONG_TYPE = Set{Integer}([2^i for i in 1:20])

# Good:
num_vector = [1.0, 2, 3] # Type will be Vector{Float64}. Float64 is concrete.
num_vector = Int[1, 2, 3] # If Int is preferred
another_vector = Array{Int128}[]
a_set = Set{Float64}([1.0, 2, 3])
double_array = Array{Array{Int64}}
triple_array = Array{Array{Array{Int32}}}
const POWERS_OF_TWO = Set{Int64}([2^i for i in 1:20])