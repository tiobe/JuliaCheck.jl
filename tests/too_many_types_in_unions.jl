# Bad style:
const ReturnTypes = Union{Nothing, String, Int32, Int64, Float64}
const Empty = Union{}   # is this even legal?

# Good style:
NonConst = Union{Nothing, Bool}     # fails other test, but OK here
const MaybeString = Union{Nothing, String}
const Threesome = Union{Nothing, String, Int64}
const FourForU = Union{Nothing, String, Int64, Float64}
