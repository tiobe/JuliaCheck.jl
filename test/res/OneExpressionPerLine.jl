# Bad style:
for bar::Int64 in range(1, 3); println("bar ", bar); if bar == 2 println("bar equals two"); end; end;

module somewhere
    x = 4; x + 5
end

# Good style:
for bar::Int64 in range(1, 3)
    println("bar ", bar)

    if bar == 2
        println("bar equals two, but correct now")
    end
end

# Ignore semicolons that are not really statement separators
for i in [1:3];
    println("i $i type ", typeof(i))
end

# Ignore semicolons in vcats
vcat_struct = [
  1 2;
  3 4
]

# Ignore semicolons in function definitions
function args_2(; a::Vector{Int64}, b::Vector{Int64})
    a[1] = 1
    b[2] = 2
end

function args_3(a::Vector{Int64}; b::Vector{Int64}, c::Vector{Int64})
    a[1] = 1
    b[2] = 2
    c[3] = 3
end

# Well, not really good, but it shouldn't throw a violation.
y = 5;
y + 6

# Another tricky one
some_string = "yeah; it's a string with a ; in it";