function my_is_nothing(value)
    return value === nothing || typeof(value) == Nothing
end
is_not_nothing(x) = x !== nothing || typeof(x) != Nothing

good_is_nothing(value) = isnothing(value)
