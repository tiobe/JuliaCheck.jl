module PrefixOfAbstractTypeNames

include("_common.jl")
using ...Properties: find_lhs_of_kind, is_upper_camel_case

struct Check <: Analysis.Check end
id(::Check) = "prefix-of-abstract-type-names"
severity(::Check) = 4
synopsis(::Check) = "Abstract type names should be prefixed by \"Abstract\"."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"abstract", node -> check(this, ctxt, node))
end

function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    @assert kind(node) == K"abstract"  "Expected an [abstract] node, got $(kind(node))"
    type_id = find_lhs_of_kind(K"Identifier", node)
    @assert type_id !== nothing "Got a type declaration without name (identifier)."
    type_name = string(type_id)
    if ! startswith(type_name, "Abstract")
        report_violation(ctxt, this, type_id,
            "Abstract type names like $type_name should have prefix \"Abstract\"."
            )
    end
end

end # module PrefixOfAbstractTypeNames

