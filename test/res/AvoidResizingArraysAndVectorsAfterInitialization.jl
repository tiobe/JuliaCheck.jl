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

function init_array_and_resize()
    e_sizehint = Int64[]
    sizehint!(e_sizehint, 2*N)
    return e_sizehint
end

function init_array_second()
    f_right = [1, 2, 3]
	f_right = []
    return f_right
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
# For resize!() we have contradicting requirements:
# 1. The `ASML Guidelines and Rules for the Julia Language` document says this is allowed
# 2. https://redmine.tiobe.com/issues/37941#note-9 says it is not allowed.
# We are taking the decision that is made last, which is 2
resize!(w_pre_allocate, index-1)


# Bad

w = []
push!(w, 1)
pushfirst!(w, 1)
pop!(w)
popfirst!(w)
append!(w, [2, 3])
prepend!(w, [2, 3])
insert!(w, 1, 5)
deleteat!(w, 1)
splice!(w, 4:3, 2)
empty!(w)
resize!(w, 100)
