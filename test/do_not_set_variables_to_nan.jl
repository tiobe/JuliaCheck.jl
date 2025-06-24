# Bad examples
value::Float64 = NaN
strct.value = NaN16
arrvalue[end] = 3 * Inf - Inf   # TODO this is not detected as NaN

"This needs a docstring"
const my_value = NaN32

# Good examples
value::Float64 = 0.0

"Just for the tests at hand."
const AdHocType = Union{Missing, Float64}
value::AdHocType = missing
