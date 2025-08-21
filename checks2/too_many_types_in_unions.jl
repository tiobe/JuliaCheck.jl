module TooManyTypesInUnions

include("_common.jl")
using ...Properties: is_union_decl

struct Check <: Analysis.Check end
id(::Check) = "too-many-types-in-unions"
severity(::Check) = 6
synopsis(::Check) = "Too many types in Unions"

const MAX_UNION_TYPES = 4

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_union_decl, node -> begin
        local union_types = children(node)[2:end] # discard the 1st, which is "Union"
        local count = length(union_types)
        if count > MAX_UNION_TYPES
            report_violation(ctxt, this, node, "Union has too many types ($count > $MAX_UNION_TYPES).")
        end
    end)
end

end
