function bad_foo(arg :: Float64) :: Nothing
    return """nothing but
            a line break, or two.
        """
end
function bad_bar(arg:: Float64):: Nothing return nothing end
function bad_kar(arg ::Float64) ::Nothing return nothing end
function bad_roo(arg ::Vector{<: Number})::Nothing return nothing end
function bad_doo(arg::Vector{ <: Number})::Nothing return nothing end

# Good style
function foo(arg::Float64)::Nothing return nothing end
function bar(arg::Vector{<:Number})::Nothing return nothing end
