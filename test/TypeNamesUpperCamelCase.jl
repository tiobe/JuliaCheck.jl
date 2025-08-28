
struct myStruct end     # Bad
struct MYSTRUCT end     # Bad
struct Mystruct end     # Bad, but undetectable, so good
struct MyStruct     # Good
    n::Int
    function MyStruct(x::AbstractString)
        new(length(x))
    end
end
abstract type myabstracttype end      # Bad

struct Parametric{T}
    x::T
    y::T
end
