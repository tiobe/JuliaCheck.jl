module AvoidCreatingEmptyArraysAndVectors

using ...Properties: get_call_name_from_call_node, is_mutating_call

include("_common.jl")

const ARRAY_MUTATING_CALLS = Set([
    "push!",
    "pushfirst!",
    "pop!",
    "popfirst!",
    "popat!",
    "append!",
    "prepend!",
    "insert!",
    "deleteat!",
    "splice!",
    "empty!",
    "resize!",
    ])

struct Check<:Analysis.Check end
Analysis.id(::Check) = "avoid-creating-empty-arrays-and-vectors"
Analysis.severity(::Check) = 8
Analysis.synopsis(::Check) = "Avoid resizing arrays after initialization."

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_mutating_call, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, call_node::SyntaxNode)::Nothing
    name = get_call_name_from_call_node(call_node)
    if name ∈ ARRAY_MUTATING_CALLS
        report_violation(ctxt, this, call_node, "Avoid resizing arrays after initialization.")
    end
    return nothing
end

end # end AvoidCreatingEmptyArraysAndVectors
