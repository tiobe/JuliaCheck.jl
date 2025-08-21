module PreferConstVariablesOverNonConstGlobalVariables

include("_common.jl")

using ...Properties: find_lhs_of_kind
using ...SyntaxNodeHelpers

struct Check <: Analysis.Check end
id(::Check) = "prefer-const-variables-over-non-const-global-variables"
severity(::Check) = 3
synopsis(::Check) = "Prefer const variables over non-const global variables"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"=", node -> begin

        ancs = ancestors(node)
        head = ancs[1:something(findfirst(is_scope_construct, ancs), length(ancs))]
        enclosing_scope = head[end]
        if (!(kind(enclosing_scope) in KSet"toplevel module baremodule")
            && !any(n -> kind(n) == K"global", head))
            # Skip assignment that is not in global scope and does not have an explicit global modifier
            return 
        end
        if any(n -> kind(n) in KSet"const local", head)
            # Skip assignment to const or local variables
            return 
        end
        glob_var = find_lhs_of_kind(K"Identifier", node)
        if glob_var !== nothing
            report_violation(ctxt, this, glob_var, "Consider making global variable $glob_var a const.")
        end
    end)
end

end # module PreferConstVariablesOverNonConstGlobalVariables
