# Bad examples
value::Float64 = Inf
strct.value = -Inf64
arrvalue[end] = Inf16

"This needs a docstring"
const my_value = Inf32

# Good examples
value::Float64 = 0.0

"Just for the tests at hand."
const AdHocType = Union{Missing, Float64}
value::AdHocType = missing
