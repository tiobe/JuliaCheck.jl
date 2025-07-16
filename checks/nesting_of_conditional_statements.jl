module NestingOfConditionalStatements

import JuliaSyntax: SyntaxNode, @KSet_str, first_byte, kind, source_location
using ...Checks: is_enabled
using ...Properties: children, get_imported_pkg, haschildren, is_flow_cntrl,
                     is_import, is_include, report_violation

const SEVERITY = 4
const RULE_ID = "nesting-of-conditional-statements"
const USER_MSG = "This conditional expression is too deeply nested (deeper than `X` levels)."
const SUMMARY = "Nesting of conditional statements."

const MAX_ALLOWED_NESTING_LEVELS = 3

function check(node::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert is_flow_cntrl(node) "Expected a flow control node, got [$(kind(node))]."

    # Count the nesting level of conditional statements
    if conditional_nesting_level(node) > MAX_ALLOWED_NESTING_LEVELS
        line, col = source_location(node)
        report_violation(; line=line, col=col, index=first_byte(node), len=2,
            severity = SEVERITY, rule_id = RULE_ID, summary = SUMMARY,
            user_msg = replace(USER_MSG, "`X`" => string(MAX_ALLOWED_NESTING_LEVELS)))
    end
end

function conditional_nesting_level(node::SyntaxNode)::Int
    level = 0
    while !isnothing(node) && kind(node) ∉ KSet"function macro module toplevel do let"
        if is_flow_cntrl(node)
            level += 1
        end
        node = node.parent
    end
    return level
end

end
