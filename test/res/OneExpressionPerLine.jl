# Bad style:
for bar::Int64 in range(1, 3); println("bar ", bar); if bar == 2 println("bar equals two"); end; end;

# Good style:
for bar::Int64 in range(1, 3)
    println("bar ", bar)

    if bar == 2
        println("bar equals two")
    end
end