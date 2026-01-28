module AvoidHardCodedNumbers

using ...Properties: get_number, is_constant, is_global_decl, is_literal_number

include("_common.jl")

""" Positive powers of 10 (up till 10^18) """
const POWERS_OF_TEN_POSITIVE = Set{Int64}([10^i for i in 1:18])

""" Negative powers of 10 (up till -10^18) """
const POWERS_OF_TEN_NEGATIVE = Set{Int64}([-i for i in POWERS_OF_TEN_POSITIVE])

""" Positive and negative powers of 10 """
const POWERS_OF_TEN = POWERS_OF_TEN_POSITIVE ∪ POWERS_OF_TEN_NEGATIVE

""" Positive powers of 2 (up till 2^20) """
const POWERS_OF_TWO = Set{Int64}([2^i for i in 1:20])

""" Integers with special meaning, such as number of seconds, degrees, etc . """
const SOME_SPECIAL_INTS = Set{Int64}([0, 1,
                                        60, # minutes, seconds
                                        90, 180, 270, 360   # degrees
                                    ])

""" Integers that are not considered magical and may appear as constants. """
const KNOWN_INTS = SOME_SPECIAL_INTS ∪ POWERS_OF_TEN ∪ POWERS_OF_TWO

""" Floats that are not considered magical and may appear as constants. """
const KNOWN_FLOATS = Set{Float64}([0.1, 0.01, 0.001, 0.0001, 0.5]) ∪
                    Set{Float64}(convert.(Float64, POWERS_OF_TEN)) ∪
                    Set{Float64}(convert.(Float64, SOME_SPECIAL_INTS))

struct Check<:Analysis.Check
    seen_before::Set{Number}

    # FIXME Fine for integers but, for floats, we should
    # probably use a tolerance to compare them.
    Check() = new(Set{Number}())
end
Analysis.id(::Check) = "avoid-hard-coded-numbers"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Avoid hard-coded numbers"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_literal_number, n -> _check(this, ctxt, n))
    return nothing
end

# Also FIXME: should I use all the 64 bits versions of the types?
function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    @assert is_literal_number(node) "Expected a node with a literal number, got $(kind(node))"
    if !_is_const_declaration(node) && !_in_array_assignment(node) && _is_magic_number(node)
        n = get_number(node)
        if n ∈ this.seen_before
            report_violation(ctxt, this, node, "Hard-coded number '$n' should be a const variable.")
        else
            push!(this.seen_before, n)
        end
    end
    return nothing
end

"""
    is_const_declaration(node::SyntaxNode)::Bool

Check if the literal number is part of a constant declaration.

To that end, we climb up the tree until we find a constant declaration, or the root.
"""
function _is_const_declaration(node::SyntaxNode)::Bool
    x = node
    while !(isnothing(x) || is_constant(x))
        x = x.parent
    end
    return !isnothing(x)
end

function _in_array_assignment(node::SyntaxNode)::Bool
    p = node.parent
    return !isnothing(p) && kind(p) == K"vect"
end

# TODO Add (unit?) tests

"""
    is_magic_number(node::SyntaxNode)::Bool

Check if the given literal is a magic number, i.e., it is not a "usual number",
i.e., one usually found in initializations.
"""
function _is_magic_number(node::SyntaxNode)::Bool
    n = get_number(node)
    return !isnothing(n) && (
                kind(node) == K"Float" ? n ∉ KNOWN_FLOATS : n ∉ KNOWN_INTS
                # Especial case π: return 3.14 <= n <= 3.15
            )
end
# TODO Add unit test

end # module AvoidHardCodedNumbers
