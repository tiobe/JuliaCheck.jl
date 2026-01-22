module GlobalVariablesUpperSnakeCase

using ...Properties: is_fat_snake_case, find_lhs_of_kind, is_assignment, is_field_assignment, NullableNode
using ...SymbolTable: is_global, node_is_declaration_of_variable
using ...SyntaxNodeHelpers: get_all_assignees

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "global-variables-upper-snake-case"
severity(::Check) = 3
synopsis(::Check) = "Casing of globals"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> is_assignment(n) && !is_field_assignment(n), n -> begin
        ids = get_all_assignees(n)
        for id in ids
            if !is_global(ctxt.symboltable, id)
                continue
            end
            if !node_is_declaration_of_variable(ctxt.symboltable, id)
                continue
            end
            var_name::String = string(id)
            if !is_fat_snake_case(var_name)
                report_violation(ctxt, this, id, "Variable '$var_name' should be written in UPPER_SNAKE_CASE")

            end
        end
    end)
end

end # module GlobalVariablesUpperSnakeCase
