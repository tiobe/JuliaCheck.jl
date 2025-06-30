module ImplementUnionsAsConsts

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Checks: is_enabled
using ...Properties: is_assignment, is_constant, is_union_decl, report_violation

const SEVERITY = 3
const RULE_ID = "asml-implement-unions-as-consts"
const USER_MSG = "Declare this Union as a const type before using it."
const SUMMARY = "Implement Unions as const."

function check(union::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert is_union_decl(union) "Expected a Union declaration, got $(kind(union))"
    if is_assignment(union.parent) && is_constant(union.parent.parent)
        # This seems to be a Union type declaration
        if union == children(union.parent)[2]
            # Confirmed. In this case, there is nothing to report.
            return nothing
        end
    end
    report_violation(union; severity = SEVERITY, rule_id = RULE_ID,
                            user_msg = USER_MSG, summary = SUMMARY)
end

end
