weights_vec = [2.2, 1.2, 3.4, 4.5]

# Bad style:
for index in 1:5 # This raises a BoundsError
    println("index $index weight $(weights_vec[index])")
end

for index in range(1:length(weights_vec))
    println("index $index weight $(weights_vec[index])")
end

index = 1
while index <= length(weight_vec)
    println("index $index weight ", weights_vec[index])
    index += 1
end

index = 1
for weight in weights_vec
    println("index $index weight $weight")
    index += 1
end

while a != b && index <= length(weights_vec) || isodd(index)
    println("index $index weight $(weights_vec[index])")
    index += 1
end

# Good style:
for index in eachindex(weights_vec)
    println("index ", index, " weight $(weights_vec[index])")
end

for weight in weights_vec
    println("weight $weight")
end
