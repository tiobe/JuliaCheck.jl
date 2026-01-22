module PreferConstVariablesOverNonConstGlobalVariables

include("_common.jl")

using ...Properties: is_assignment, is_global_decl
using ...SyntaxNodeHelpers: get_all_assignees, ancestors, is_scope_construct

struct Check<:Analysis.Check end
id(::Check) = "prefer-const-variables-over-non-const-global-variables"
severity(::Check) = 3
synopsis(::Check) = "Prefer const variables over non-const global variables"

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, n -> is_global_decl(n) && is_assignment(n), node -> begin
        lhs = first(children(node))
        if kind(lhs) ∈ KSet". ref" # Exclude mutation (field assignment `A.x = 1` or array mutation `A[i] = 1`)
            return nothing
        end
        glob_vars = get_all_assignees(node)
        for glob_var in glob_vars
            if !isnothing(glob_var) && !has_const_annotation(glob_var)
                report_violation(ctxt, this, glob_var, "Consider making global variable '$glob_var' a const.")
            end
        end
    end)
end

function has_const_annotation(node::SyntaxNode)::Bool
    ancs = ancestors(node)
    head = ancs[1:something(findfirst(is_scope_construct, ancs), length(ancs))]
    return any(n -> kind(n) == K"const", head)
end

end # module PreferConstVariablesOverNonConstGlobalVariables
