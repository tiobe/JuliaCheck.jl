module AvoidHardCodedNumbers
                    
include("_common.jl")

using ...Properties: get_number, is_constant, is_global_decl, is_literal_number

struct Check <: Analysis.Check 
    seen_before # FIXME Fine for integers but, for floats, we should
                # probably use a tolerance to compare them.
    Check() = new(Set{Number}())                      
end
id(::Check) = "avoid-hard-coded-numbers"
severity(::Check) = 3
synopsis(::Check) = "Avoid hard-coded numbers."
const USER_MSG = "Implement hard-coded numbers via a const variable."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, 
        n -> is_literal_number(n), n -> check(this, ctxt, n))
end

# Also FIXME: should I use all the 64 bits versions of the types?
function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    @assert is_literal_number(node) "Expected a node with a literal number, got $(kind(node))"
    if !is_const_declaration(node) && is_magic_number(node)
        n = get_number(node)
        if n ∈ this.seen_before
            report_violation(ctxt, this, node, USER_MSG)
        else
            push!(this.seen_before, n)
        end
    end
end

"""
    is_const_declaration(node::SyntaxNode)::Bool

Check if the literal number is part of a constant declaration.

To that end, we climb up the tree until we find a constant declaration, or the root.
"""
function is_const_declaration(node::SyntaxNode)::Bool
    x = node
    while !( isnothing(x) || is_constant(x) )
        x = x.parent
    end
    return !isnothing(x)
end
# TODO Add (unit?) tests

## Magic numbers
# Integers
const POWERS_OF_TEN_POSITIVE = Set{Int64}([10^i for i in 1:20])
const POWERS_OF_TEN_NEGATIVE = Set{Int64}([-i for i in POWERS_OF_TEN_POSITIVE])
const POWERS_OF_TEN = POWERS_OF_TEN_POSITIVE ∪ POWERS_OF_TEN_NEGATIVE
const POWERS_OF_TWO = Set{Int64}([2^i for i in 1:20])
const SOME_SPECIAL_INTS = Set{Int64}([0, 1,
                                        60, # minutes, seconds
                                        90, 180, 270, 360   # degrees
                                    ])
const KNOWN_INTS = SOME_SPECIAL_INTS ∪ POWERS_OF_TEN ∪ POWERS_OF_TWO
# Floats
const KNOWN_FLOATS = Set{Float64}([0.1, 0.01, 0.001, 0.0001, 0.5]) ∪
                     Set{Float64}(convert.(Float64, POWERS_OF_TEN))
                     Set{Float64}(convert.(Float64, SOME_SPECIAL_INTS))
"""
    is_magic_number(node::SyntaxNode)::Bool

Check if the given literal is a magic number, i.e., it is not a "usual number",
i.e., one usually found in initializations.
"""
function is_magic_number(node::SyntaxNode)::Bool
    n = get_number(node)
    return !isnothing(n) && (
                kind(node) == K"Float" ? n ∉ KNOWN_FLOATS : n ∉ KNOWN_INTS
                # Especial case π: return 3.14 <= n <= 3.15
            )
end
# TODO Add unit test

end # module AvoidHardCodedNumbers

