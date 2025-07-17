weights_vec = [2.2, 1.2, 3.4, 4.5]

# Bad style:
for index in 1:5 # This raises a BoundsError
    println("index $index weight $(weights_vec[index])")
end

for index in range(1:length(weights_vec))
    println("index $index weight $(weights_vec[index])")
end

# Good style:
for index in eachindex(weights_vec)
    println("index ", index, " weight $(weights_vec[index])")
end

for weight in weights_vec
    println("weight $weight")
end

for i in 1:10
    println("i = $i")
end
