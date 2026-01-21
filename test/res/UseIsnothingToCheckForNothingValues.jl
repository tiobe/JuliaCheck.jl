# Bad style:
if value === nothing end
if value !== nothing end
if value == nothing end
if value != nothing end
if nothing == value end
if nothing != value end

# Good style:
if isnothing(nothing) end
if !isnothing(nothing) end

# RM-37345: comparison to the type Nothing is allowed (contrary to the example in the JCS)
if typeof(nothing) == Nothing end
