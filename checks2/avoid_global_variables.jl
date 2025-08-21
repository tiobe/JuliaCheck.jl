module AvoidGlobalVariables

using ..SymbolTable: is_global
using ...Properties: is_assignment, is_fat_snake_case, find_lhs_of_kind, NullableNode

include("_common.jl")

struct Check <: Analysis.Check end
id(::Check) = "avoid-global-variables"
severity(::Check) = 3
synopsis(::Check) = "Avoid global variables when possible."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> is_assignment(n), n -> begin
        id::NullableNode = find_lhs_of_kind(K"Identifier", n)
        if id !== nothing && is_global(ctxt.symboltable, id)
            report_violation(ctxt, this, id, "Avoid global variables wherever possible.")
        end
    end)
end

end
