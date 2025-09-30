# Bad style:
for bar::Int64 in range(1, 3); println("bar ", bar); if bar == 2 println("bar equals two"); end; end;

x = 4; x + 5

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

# Well, not really good, but it shouldn't throw a violation.
y = 5;
y + 6