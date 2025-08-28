# Bad style:
spam( ham[ 1 ], [ eggs ] )

x = [
    [1 2   3];
    [4 567 8]
]
y = [  1, 3,  5 ]
f(; x = 10)
y_dict = Dict{ String, Int}( "apple" =>  1, "banana"  => 2)

# Good style:
spam(ham[1], [eggs])

x = [
    [1 2 3];
    [4 567 8]
]
y = [1, 3, 5]
f(; x=10)
x = 10 # This should not require space, because not a function parameter
y_dict = Dict{String, Int}("apple" => 1, "banana" => 2)