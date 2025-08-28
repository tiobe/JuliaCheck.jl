module GlobalVariablesUpperSnakeCase

using ...Properties: is_fat_snake_case, is_global_decl, find_lhs_of_kind, is_assignment, NullableNode
using ...SymbolTable

include("_common.jl")

struct Check<:Analysis.Check
    already_reported::Set{SyntaxNode}
    Check() = new(Set{SyntaxNode}())
end
id(::Check) = "global-variables-upper-snake-case"
severity(::Check) = 3
synopsis(::Check) = "Casing of globals"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> is_assignment(n), n -> begin
        id::NullableNode = find_lhs_of_kind(K"Identifier", n)
        if !isnothing(id)
            if ! is_global(ctxt.symboltable, id)
                return nothing
            end
            var_name::String = string(id)
            if !is_fat_snake_case(var_name)
                report_violation(ctxt, this, id, "Variable $var_name should be written in UPPER_SNAKE_CASE.")
            end
        end
    end)
end

end # module GlobalVariablesUpperSnakeCase
