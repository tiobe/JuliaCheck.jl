module PreferConstVariablesOverNonConstGlobalVariables

include("_common.jl")

using ...Properties: find_lhs_of_kind, is_assignment, is_global_decl, get_all_assignees
using ...SyntaxNodeHelpers

struct Check<:Analysis.Check end
id(::Check) = "prefer-const-variables-over-non-const-global-variables"
severity(::Check) = 3
synopsis(::Check) = "Prefer const variables over non-const global variables"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> is_global_decl(n) && is_assignment(n), node -> begin
        ancs = ancestors(node)
        head = ancs[1:something(findfirst(is_scope_construct, ancs), length(ancs))]
        enclosing_scope = head[end]
        if !(kind(enclosing_scope) in KSet"toplevel module baremodule")
            # Skip assignment that is not in global scope
            return
        end
        if any(n -> kind(n) in KSet"const local", head)
            # Skip assignment to const or local variables
            return
        end
        glob_vars = get_all_assignees(node)
        for glob_var in glob_vars
            if glob_var !== nothing
                report_node = kind(glob_var) == K"::" ? first(children(glob_var)) : glob_var
                report_violation(ctxt, this, report_node, "Consider making global variable $report_node a const.")
            end
        end
    end)
end

end # module PreferConstVariablesOverNonConstGlobalVariables
