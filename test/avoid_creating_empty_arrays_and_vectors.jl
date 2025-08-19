
# Bad
a_wrong = empty([1.0, 2.0, 3.0])
b_wrong = empty([1.0, 2.0, 3.0], String)
c_wrong = Array{Float64}[]

function init_array_wrong()
    d_wrong = []
    return d_wrong
end

v = []
for i in 1:100
    push!(v, i^2)
end

w = []
N = 100
for _ in 1:N
    value = rand(1:10)
    if iseven(value)
        push!(w, value)
        push!(w, value ÷ 2)
    else
        push!(w, value)
    end
end

# Good
c_right = Array{Float64}(undef, 5)
v_comprehension = [i^2 for i in 1:100]
v_map = map(i -> i^2, 1:100)
square(x) = x^2
v_broadcast = square.(1:100)

function init_array_right()
    d_right = [1, 2, 3]
    return d_right
end

N = 100
w_pre_allocate = Vector{Int64}(undef, 2*N)
index = 1
for _ in 1:N
    value = rand(1:10)
    if iseven(value)
        w_pre_allocate[index] = value
        w_pre_allocate[index+1] = value ÷ 2
        index += 2
    else
        w_pre_allocate[index] = value
        index += 1
    end
end
resize!(w_pre_allocate, index-1)

# TODO: sizehint case
# TODO: not_initialized case