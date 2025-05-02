function foo1(HamList::Vector{<:Real}) println(HamList) end
function foo2(ham_list::Vector{<:Real})::Nothing println(ham_list) end

∑(x, y) = x + y
a_lambda = (arg_one, ArgTwo) -> (arg_one + ArgTwo)
