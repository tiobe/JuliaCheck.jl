module GlobalVariablesUpperSnakeCase

using ..SymbolTable: is_global
using ...Properties: is_assignment, is_fat_snake_case, find_lhs_of_kind, NullableNode

include("_common.jl")

struct Check <: Analysis.Check end
id(::Check) = "global-variables-upper-snake-case"
severity(::Check) = 3
synopsis(::Check) = "Casing of globals"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> is_assignment(n), n -> begin
        id::NullableNode = find_lhs_of_kind(K"Identifier", n)
        if ! is_global(ctxt.symboltable, id)
            return nothing
        end
        if id !== nothing
            var_name::String = string(id)
            if !is_fat_snake_case(var_name)
                report_violation(ctxt, this, id, "Variable $var_name should be written in UPPER_SNAKE_CASE.")
            end
        end
    end)
end

end
