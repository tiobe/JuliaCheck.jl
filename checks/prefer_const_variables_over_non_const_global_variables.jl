module PreferConstVariablesOverNonConstGlobalVariables

using JuliaSyntax: SyntaxNode, @K_str, children, kind
using ...Checks: is_enabled
using ...Properties: is_assignment, get_assignee, report_violation

const RULE_ID = "prefer-const-variables-over-non-const-global-variables"
const USER_MSG = "Consider making global variable a const."
const SUMMARY = "Prefer const variables over non-const global variables."
const SEVERITY = 3

function check(glob_var::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(glob_var) == K"Identifier" "Expected an [Identifier] node, got [$(kind(glob_var))]."
    report_violation(glob_var; severity = SEVERITY, rule_id = RULE_ID,
                               user_msg = "Consider making global variable $glob_var a const.",
                               summary = SUMMARY)
end

end
