module GlobalVariablesUpperSnakeCase

using ...Properties: is_fat_snake_case, is_global_decl, find_lhs_of_kind, NullableNode

include("_common.jl")

struct Check <: Analysis.Check 
    already_reported::Set{SyntaxNode}
    Check() = new(Set{SyntaxNode}())
end
id(::Check) = "global-variables-upper-snake-case"
severity(::Check) = 3
synopsis(::Check) = "Casing of globals"

function init(this::Check, ctxt::AnalysisContext)
    # FIXME: this does not check whether identifier refers to global variable
    # We need use a proper symbol table for this.
    # For now, we use already_reported set.

    register_syntaxnode_action(ctxt, n -> is_global_decl(n), n -> begin
        id::NullableNode = find_lhs_of_kind(K"Identifier", n)
        if id !== nothing
            if id ∈ this.already_reported
                return
            end
            push!(this.already_reported, id)

            var_name::String = string(id)
            if !is_fat_snake_case(var_name)
                report_violation(ctxt, this, id, "Variable $var_name should be written in UPPER_SNAKE_CASE.")
            end
        end
    end)
end

end
