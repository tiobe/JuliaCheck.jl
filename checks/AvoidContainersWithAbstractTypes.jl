module AvoidContainersWithAbstractTypes

using JuliaSyntax: is_leaf
using ...Properties: is_assignment, NullableNode

include("_common.jl")

#=
The intent of this rule is to work with the Julia optimization:
https://docs.julialang.org/en/v1/manual/arrays/
https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-abstract-container

> In general, unlike many other technical computing languages, Julia does not expect programs to be written
> in a vectorized style for performance. Julia's compiler uses type inference and generates optimized code
> for scalar array indexing, allowing programs to be written in a style that is convenient and readable,
> without sacrificing performance, and using less memory at times.

And if any abstract number type is used, then I presume that Julia cannot do this.

Unfortunately, it does not seem to be possible to do this programmatically. JuliaSyntax has no
in-depth knowledge of the Julia type system, and to check it as types in Julia itself seems to
require eval hackery, which is potentially risky.
=#

"""
Set of all the abstract number types that can be flagged for usage in a container.

The documentation page https://docs.julialang.org/en/v1/base/numbers/ was used for this set.
"""
const ABSTRACT_NUMBER_TYPES = Set([
    "Number",
    "Real",
    "AbstractFloat",
    "Integer",
    "Signed",
    "Unsigned",
    "AbstractIrrational",
])

struct Check<:Analysis.Check end
id(::Check) = "avoid-containers-with-abstract-types"
severity(::Check) = 6
synopsis(::Check) = "Avoid containers with abstract types."

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_container, n -> check(this, ctxt, n))
    return nothing
end

# Structure of a typical node we want to check here:
# (= num_vector (ref Real 1.0 2 3))
# We want to check the type right-hand side of the assignment.
# For some invocations, this is also wrapped inside a call (eg. list comprehensions)
function is_container(node::SyntaxNode)::Bool
    if !is_assignment(node) || numchildren(node) < 2
        return false
    end
    rhs = children(node)[2]
    return !is_leaf(rhs) && kind(rhs) in KSet"ref call curly"
end

function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    assignment_rhs = children(node)[2]
    id_type_node = _get_identifier_node_to_check(assignment_rhs)
    if !isnothing(id_type_node)
        type_to_check = string(id_type_node)
        if type_to_check ∈ ABSTRACT_NUMBER_TYPES
            report_violation(
                ctxt,
                this,
                id_type_node,
                "Type '$type_to_check' is an abstract number type and should not be used as a container type.",
            )
        end
    end
    return nothing
end

# Curly braces notations get translated like this:
# - Array{Number}[] => (curly Array Number)
# - Array{Array}{Number}[] => (curly Array (curly Array Number))
# As such, to find the type of multidimensional arrays, it's convenient to be able
# to walk down the tree until an identifier is found.
function _get_identifier_node_to_check(node::SyntaxNode)::NullableNode
    while _search_further(node)
        node = _get_next_search_node(node)
    end
    if !isnothing(node) && kind(node) == K"Identifier"
        return node
    end
    return nothing
end

function _search_further(node::NullableNode)::Bool
    if isnothing(node) || is_leaf(node) || kind(node) == K"Identifier"
        return false
    end
    return true
end

function _get_next_search_node(node::SyntaxNode)::NullableNode
    if kind(node) ∈ KSet"ref call"
        return children(node)[1]
    elseif kind(node) == K"curly"
        return children(node)[2]
    end
    return nothing
end

end # end AvoidContainersWithAbstractTypes
