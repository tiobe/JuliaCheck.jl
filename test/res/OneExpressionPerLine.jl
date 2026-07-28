# Bad style:
for bar::Int64 in range(1, 3); println("bar ", bar); if bar == 2 println("bar equals two"); end; end;

# Should be written as two specific violations,
# not just one on the entire block!
module somewhere
    x = 4; x + 5
    y = 6; z = 11;
end

module well_this_is_another_one
    clumsy_setup = []
    push!(clumsy_setup, 1); push!(clumsy_setup, 2)
end

module inline_cleverness
    x = 5; x + 5; x * 5;
end

module module_with_deep_nesting
    if true
        a = 5;
        b = 6; a = 4; # Violation expected here
    else
        a = 5
        if false
            a = 6;
        else
            a= 7; b = 9; # Violation also expected here
        end
    end
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
another_vcat = [1 3; 2 4]

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

# Ignore semicolons in function calls
args_3([1]; b=[2, 2], c=[3, 3, 3])

# Well, not really good, but it shouldn't throw a violation.
y = 5;
y + 6
array_def = [];
push!(array_def, 1);

# Another tricky one
some_string = "yeah; it's a string with a ; in it"; # Some comment

module innocent_mistake
    clumsy_setup = []
    push!(clumsy_setup, 1)
    push!(clumsy_setup, 2); # Some comment
end

module using_comments_RM37947
    x = 5 #= Block comments... =#; #=  ...are also allowed =#
    x + 5; # This is a comment2
end


