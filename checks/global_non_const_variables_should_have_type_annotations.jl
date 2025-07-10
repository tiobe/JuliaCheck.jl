module GlobalNonConstVariablesShouldHaveTypeAnnotations

using JuliaSyntax: SyntaxNode, @K_str, children, haschildren, kind
using ...Checks: is_enabled
using ...Properties: first_child, get_assignee, is_assignment, is_constant, is_global_decl,
                    report_violation

const RULE_ID = "global-non-const-variables-should-have-type-annotations"
const USER_MSG = "Global non-const variable does not have a type annotation."
const SUMMARY = "Global non-const variables should have type annotations."
const SEVERITY = 6

function check(glob_var::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    # This must not be a [const], so it must be [global].
    @assert is_global_decl(glob_var) "Expected a global declaration, got [$(kind(glob_var))]."
    @assert !is_constant(glob_var) "Run this check on non-const global declarations only!"
    if !haschildren(glob_var)
        @debug "Global declaration has no children, skipping check." glob_var
        return nothing
    end
    if kind(glob_var) == K"global" glob_var = first_child(glob_var) end
    if kind(glob_var) == K"="      glob_var = first_child(glob_var) end
    if kind(glob_var) != K"::"
        report_violation(glob_var;
            severity = SEVERITY, rule_id = RULE_ID,
            user_msg = "Global non-const variable $glob_var does not have a type annotation.",
            summary = SUMMARY)
    end
end

end
