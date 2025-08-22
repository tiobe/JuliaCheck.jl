my_is_missing(value) = value == missing || typeof(value) ≠ Missing
my_not_missing(value) = value != missing || typeof(value) != Missing
good_is_missing(value) = ismissing(value)
bad_lhs_missing(value) = missing != (value + 3)
