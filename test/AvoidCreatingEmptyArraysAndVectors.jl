# Bad style:
struct S{U} <: T
    t::U
end

# Good style:
abstract type AbstractFruit end
abstract type AbstractFruitProperties end

struct StoneFruitProperties <: AbstractFruitProperties
    pit_weight::Float64
end

struct CitrusFruitProperties <: AbstractFruitProperties
    poisonous_skin::Bool
end

struct Fruit{F <: AbstractFruitProperties} <: AbstractFruit
    fruit_properties::F
    weight::Float64
    volume::Float64
end
```

## Variables have a fixed type
Rule id: variables-have-fixed-types \
Severity: 3 \
User message: Variable `$X` should not change type.

A variable will not change type during its lifetime.
If a variable changes type within a function body the compiler has more difficulty with optimization of this function body.
This is explicitly mentioned in the official Julia documentation [here](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-changing-the-type-of-a-variable).

> Rationale: performance

```Julia
# Bad style:
function f()
    x = 5
    x = x/2
    y = x^2
    return y
end

function g()
    x = 5
    x = string(x)
    y = x * "_suffix"
    return y
end

# Good style:
function f()
    x = 5.0
    x = x/2
    y = x^2
    return y
end

function g()
    x = 5
    x_string = string(x)
    y = x_string * "_suffix"
    return y
end
```

## Avoid creating empty arrays and vectors
Rule id: avoid-creating-empty-arrays-and-vectors \
Severity:  8 \
User message: Avoid resizing arrays after initialization.

When populating an array it is best to immediately create it with the correct size.
Constantly resizing an array incurs a performance impact where you constantly have to reassign memory and move data around.
Immediately create the array of the correct size to avoid any need for resizing.
If this is not possible use `sizehint!` with a sufficiently large size estimate.
There are a number of ways to handle this in an elegant way: list comprehensions, maps, ...; see the examples below for some ways of handling this.
It can happen that you do not know beforehand how to construct every element of the required array, in this case the use of preallocation or `sizehint!` is appropriate.
But the solutions where the array is immediately constructed with the required elements are preferred since this way we do not need to specify the type by hand and let the type inference handle this for us.
Also see the [Pre-allocating outputs](https://docs.julialang.org/en/v1/manual/performance-tips/#Pre-allocating-outputs) section of the Julia documentation for a related construction.

> Rationale: performance

```Julia
# Bad style:
v = []
for i in 1:100
    push!(v, i^2)
end

w = []
N = 100
for _ in 1:N
    value = rand(1:10)
    if iseven(value)
        push!(w, value)
        push!(w, value ÷ 2)
    else
        push!(w, value)
    end
end

# Good style:
v_comprehension = [i^2 for i in 1:100]
v_map = map(i -> i^2, 1:100)
square(x) = x^2
v_broadcast = square.(1:100)

N = 100
w_pre_allocate = Vector{Int64}(undef, 2*N)
index = 1
for _ in 1:N
    value = rand(1:10)
    if iseven(value)
        w_pre_allocate[index] = value
        w_pre_allocate[index+1] = value ÷ 2
        index += 2
    else
        w_pre_allocate[index] = value
        index += 1
    end
end
resize!(w_pre_allocate, index-1)

N = 100
w_sizehint = Int64[]
sizehint!(w_sizehint, 2*N)
for _ in 1:N
    value = rand(1:10)
    if iseven(value)
        push!(w_sizehint, value)
        push!(w_sizehint, value ÷ 2)
    else
        push!(w_sizehint, value)
    end
end
