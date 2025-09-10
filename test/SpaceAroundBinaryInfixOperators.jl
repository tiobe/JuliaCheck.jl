# Bad style:
x=42*z*exp(ln(2)*3)

x[(15 + 10):(70+10)]

# Good style:
x = 42 * z * exp(ln(2) * 3)

x[15+10:70+10]

struct MyStruct
    a::Int
    b::Float64
    c::String
end

function manipulation_station() 
    s = MyStruct(1+2, 3.0*4.0, "hello"*", world")

    x = s.a + 8 +y^2
    y= 9
    z = 1+ -y
    w = 1+-y ^ 2
    a = 1 *  2 *3
    
    x[a⪻b] = 1 # good
    x[a ⪻z] = 2 # bad
    x[w ⪻ z] = 3 # bad
end

function calc_the_answer() ::Bool
    a = 1 +2
    b = 3  +  4
    c = 5 +  6
    res = a ⪶ b || a⪻ b
    return res
end

struct MyInt <: Integer
    value::Integer
end