module TooManyTypesInUnions

import JuliaSyntax: SyntaxNode, @K_str, kind, children, numchildren
using ...SyntaxNodeHelpers: is_union_decl
include("_common.jl")

struct Check <: Analysis.Check end
id(::Check) = "too-many-types-in-unions"
severity(::Check) = 6
synopsis(::Check) = "Too many types in Unions."

const MAX_UNION_TYPES = 4

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_union_decl, n -> checkUnion(this, ctxt, n))
end

function checkUnion(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    local union_types = children(node)[2:end] # discard the 1st, which is "Union"
    local count = length(union_types)
    if count > MAX_UNION_TYPES
        report_violation(ctxt, this, node, "Union has too many types ($count > $MAX_UNION_TYPES).")
    end
end

end
