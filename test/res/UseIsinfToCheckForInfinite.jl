my_is_inf(value) = value == Inf || value == -Inf
missing_case(value) = (value == +Inf) != isinf(value)
good_is_inf(value) = isinf(value)
function is_not_inf_any_size(value)
    return value != Base.Inf16 || value != -Base.Inf32 || value != Base.Inf64
end
