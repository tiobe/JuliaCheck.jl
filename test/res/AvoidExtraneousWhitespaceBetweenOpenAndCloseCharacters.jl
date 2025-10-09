# Bad style:
spam( ham[ 1 ], [ eggs ] )

x = [
    [1 2   3];
    [4 567 8]
]
y = [  1, 3,  5 ]
f(; x = 10)
y_dict = Dict{ String, Int}( "apple" =>  1, "banana"  => 2)
tuple = ( a , b, c )
block = ( a ; b; c )

# Good style:
spam(ham[1], [eggs])

x = [
    [1 2 3];   # whitespace is succeeded by comment
    [4 567 8]
]
y = [1, 3, 5]
f(; x=10)
x = 10 # This should not require space, because not a function parameter
y_dict = Dict{String, Int}("apple" => 1, "banana" => 2)
tuple = (a, b, c)
block = (a; b; c)

# RM-37280: Avoid false positives
struct FresnelCoefficientContext
    ringWidth::Float64 = 0.003                       #width of ring
    ringCenter::Float64 = 0.145                      #center of ring
end
const KNOWN_FLOATS = Set{Float64}([0.1, 0.01, 0.001, 0.0001, 0.5]) ∪
                    Set{Float64}(convert.(Float64, POWERS_OF_TEN))
if kind(glob_var) == K"="      glob_var = first_child(glob_var) end
@assert true  "a" * "b"
