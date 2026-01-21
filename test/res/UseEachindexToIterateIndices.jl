weights_vec = [2.2, 1.2, 3.4, 4.5, 5.6]

# Bad style:
for index in 1:5 # One violation on `index`
    println("index $index weight $(weights_vec[index])")
    b = weights_vec[index] # Violation should only be reported once
end

for index in 1:5 # Violation on `index`
    while false # while-loop should not affect the violation
        a = weights_vec[index]
    end
end

for index in range(1, length(weights_vec)) # Violation on `index`
    println("index $index weight $(weights_vec[index])")
end

for i1 in 1:2 # Violation on `i1`
    for i2 in 1:2 # Violation on `i2`
        println(weights_vec[i1] + weights_vec[i2])
    end
end

for i in 1:length(nested_collection)
    for j in 1:length(nested_collection[i])
        nested_collection[i][j]
    end
end

# Good style:
for index in eachindex(weights_vec)
    for i in 1:5 # For-loop with range, but is not used an array index
        println("index ", i, " weight $(weights_vec[index])")
    end
end

for weight in weights_vec
    println("weight $weight")
end

for i in 1:2
    println("i = $i")
    println(weights_vec[i*2]) # Loop variable used in an expression should be ignored
end
