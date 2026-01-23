module PreferConstVariablesOverNonConstGlobalVariables

include("_common.jl")

using ...Properties: is_assignment, is_global_decl
using ...SyntaxNodeHelpers: ancestors, get_all_assignees, is_scope_construct

struct Check<:Analysis.Check end
Analysis.id(::Check) = "prefer-const-variables-over-non-const-global-variables"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Prefer const variables over non-const global variables"

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> is_global_decl(n) && is_assignment(n), node -> begin
        ancs = ancestors(node)
        head = ancs[1:something(findfirst(is_scope_construct, ancs), length(ancs))]
        enclosing_scope = head[end]
        if any(n -> kind(n) == K"const", head)
            # Skip assignment to const variables
            return
        end
        glob_vars = get_all_assignees(node)
        for glob_var in glob_vars
            if !isnothing(glob_var)
                report_violation(ctxt, this, glob_var, "Consider making global variable '$glob_var' a const.")
            end
        end
    end)
end

end # module PreferConstVariablesOverNonConstGlobalVariables
