module PrefixOfAbstractTypeNames

include("_common.jl")
using ...Properties: find_lhs_of_kind, is_upper_camel_case

struct Check<:Analysis.Check end
Analysis.id(::Check) = "prefix-of-abstract-type-names"
Analysis.severity(::Check) = 4
Analysis.synopsis(::Check) = "Abstract type names should be prefixed by \"Abstract\"."

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"abstract", node -> _check(this, ctxt, node))
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    @assert kind(node) == K"abstract"  "Expected an [abstract] node, got $(kind(node))"
    type_id = find_lhs_of_kind(K"Identifier", node)
    @assert ! isnothing(type_id) "Got a type declaration without name (identifier)."
    type_name = string(type_id)
    if ! startswith(type_name, "Abstract")
        report_violation(ctxt, this, type_id,
            "Abstract type names like $type_name should have prefix \"Abstract\"."
            )
    end
end

end # module PrefixOfAbstractTypeNames

