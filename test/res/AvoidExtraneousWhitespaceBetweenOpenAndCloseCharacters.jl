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
struct Context
    width::Float64 = 1.000                       #width
    center::Float64 = 1.000                      #center
end
hints = ([0, 1,
        60,                 # minutes, seconds
        90, 180, 270, 360   # degrees
    ])
const KNOWN_FLOATS = Set{Float64}([0.1, 0.01, 0.001, 0.0001, 0.5]) ∪
                    Set{Float64}(convert.(Float64, POWERS_OF_TEN))
if kind(glob_var) == K"="      glob_var = first_child(glob_var) end
@assert true  "a" * "b"

# RM-37281: Avoid false positives
m_vec .-= 1  # Rows and columns as returned by _vector_index_to_matrix_row_col!
function Base.isapprox(context1::Context, context2::Context; kwargs...)
    equal::Bool = context1.a           == context2.a          &&
                  context1.m           == context2.m               &&
                  context1.n           == context2.n
end
