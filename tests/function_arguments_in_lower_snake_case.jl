function foo1(HamList::Vector{<:Real}) println(HamList) end
function foo2(ham_list::Vector{<:Real})::Nothing println(ham_list) end

∑(x, y) = x + y

function foo(x, y; NamedArg::String="nothing")
    if x == y
        println(NamedArg)
    end
end
bar(x, y; named_arg) = x + y
kar(x, y; named_arg::String) = x + y
far(; NamedArg::Int) = named_arg
fck(;) = π


# !(x::Bool) = not_int(x)
# (~)(x::Bool) = !x
# (&)(x::Bool, y::Bool) = and_int(x, y)
# (|)(x::Bool, y::Bool) = or_int(x, y)
