Base.@kwdef mutable struct Location
    x::Symbol = :x
    y::Symbol = :y
end

# something here which triggers a new toplevel
const LOCATION = Location();