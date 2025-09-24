"""
This is bad style: too many types in a union.
"""
const ReturnTypes = Union{Nothing, String, Int32, Int64, Float64}

"""Is this even legal?"""
const Empty = Union{}

"""Kinda good style, but should be const"""
NonConst = Union{Nothing, Bool}     # fails other test, but OK here
"""Good style"""
const MaybeString = Union{Nothing, String}
"""Good style"""
const Threesome = Union{Nothing, String, Int64}
"""Good style"""
const FourForU = Union{Nothing, String, Int64, Float64}
