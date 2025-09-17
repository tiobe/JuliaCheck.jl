module AvoidContainersWithAbstractTypes

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
# We want to check the right-hand side of the assignment:
# - and whether that has any type specifiers,
# - and whether any one of those type specifiers is an abstract type.
function is_container(node::SyntaxNode)::Bool
    if !is_assignment(node)
        return false
    end
    if numchildren(node) < 2
        return false
    end
    rhs = children(node)[2]
    if numchildren(rhs) > 0 && kind(rhs) == K"ref"
        return true
    end
    return false
end

function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    assignment_rhs = children(node)[2]
    node_to_check_for_type = first(children(assignment_rhs))
    node_containing_type = _get_node_to_check(node_to_check_for_type)
    if !isnothing(node_containing_type)
        type_to_check = string(node_containing_type)
        if type_to_check ∈ ABSTRACT_NUMBER_TYPES
            report_violation(
                ctxt,
                this,
                node_containing_type,
                "Type '$type_to_check' is an abstract number type and should not be used as a container type.",
            )
        end
    end
    return nothing
end

function _get_node_to_check(node::SyntaxNode)::NullableNode
    if kind(node) == K"Identifier"
        return node
    end
    # Curly braces notations get translated like this, so we want the second child:
    # Array{Number}[] => (curly Array Number)
    if kind(node) == K"curly"
        return children(node)[2]
    end
    return nothing
end

end # end AvoidContainersWithAbstractTypes
