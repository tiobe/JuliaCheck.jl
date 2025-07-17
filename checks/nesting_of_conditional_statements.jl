module NestingOfConditionalStatements

import JuliaSyntax: SyntaxNode, @KSet_str, first_byte, kind, source_location
using ...Checks: is_enabled
using ...Properties: is_flow_cntrl, report_violation

const MAX_ALLOWED_NESTING_LEVELS = 3

const SEVERITY = 4
const RULE_ID = "nesting-of-conditional-statements"
const USER_MSG = "This conditional expression is too deeply nested (deeper than $MAX_ALLOWED_NESTING_LEVELS levels)."
const SUMMARY = "Nesting of conditional statements."

function check(node::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert is_flow_cntrl(node) "Expected a flow control node, got [$(kind(node))]."

    # Count the nesting level of conditional statements
    if conditional_nesting_level(node) > MAX_ALLOWED_NESTING_LEVELS
        line, col = source_location(node)
        report_violation(; line=line, col=col, index=first_byte(node),
                            len=length(string(kind(node))),
                            severity = SEVERITY, rule_id = RULE_ID,
                            summary = SUMMARY, user_msg = USER_MSG)
    end
end

function conditional_nesting_level(node::SyntaxNode)::Int
    level = 0
    while (!isnothing(node) &&
           kind(node) ∉ KSet"function macro module toplevel do let")
        if is_flow_cntrl(node)
            level += 1
        end
        node = node.parent
    end
    return level
end

end
