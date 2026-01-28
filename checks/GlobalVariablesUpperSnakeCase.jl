module GlobalVariablesUpperSnakeCase

using ...Properties: is_fat_snake_case, is_assignment, is_field_assignment
using ...SymbolTable: is_global, node_is_declaration_of_variable
using ...SyntaxNodeHelpers: get_all_assignees

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "global-variables-upper-snake-case"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Casing of globals"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
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
    return nothing
end

end # module GlobalVariablesUpperSnakeCase
