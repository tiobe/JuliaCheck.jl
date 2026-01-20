function BadFunName(x::T) where T<:Any return x end
function Get_Bacon()::Bacon return nothing end
function Get_bacon()::Bacon return nothing end
function GetBacon()::Bacon return nothing end
function Getbacon()::Bacon return nothing end
function get_Bacon()::Bacon return nothing end
function getBacon()::Bacon return nothing end
function get_SPAM_from_somewhere()::SPAM return nothing end
RetrieveBacon() = nothing
retrieve_Bacon() = nothing

# Good
function get_bacon()::Bacon return nothing end
retrieve_bacon() = nothing

# RM-37316: do not trigger on extension of a function defined in another module.
StructTypes.StructType(::Type{Measurement}) = StructTypes.Struct()
function Base.String(s::SomeString)
    return s
end
A.B.C(arg) = "bar" # Extensions in nested module
