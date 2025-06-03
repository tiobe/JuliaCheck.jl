module no_whitespace_around_type_operators

module Bad
    function foo(arg :: Float64) :: Nothing
        return """nothing but
                a line break, or two.
            """
    end
    function bar(arg:: Float64):: Nothing return round(arg) end
    function kar(arg ::Float64) ::Nothing return round(arg) end
    function roo(arg ::Vector{<: Number})::Nothing return length(arg) end
    function doo(arg::Vector{ <: Number})::Nothing return length(arg) end
    Base.string(:: Type{NotOKStatus}) = "NOK"
end # Bad

module Good
    function foo(arg::Float64)::Nothing return round(arg) end
    function bar(arg::Vector{<:Number})::Nothing return length(arg) end
    ACM.create_model_type(::Val{Symbol("fres0comb")}) = Fresnel(0, CombinedDirection())
    Base.string(::Type{OKStatus}) = "OK"
end # Good

end # module no_whitespace_around_type_operators
