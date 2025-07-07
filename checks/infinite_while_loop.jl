module InfiniteWhileLoop

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Checks: is_enabled
using ...Properties: haschildren, report_violation

const SEVERITY = 5
const RULE_ID = "infinite-while-loop"
const USER_MSG = "Implement a proper stop criterion for this while loop."
const SUMMARY = "Do not use while true."

function check(wyle::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(wyle) == K"while" "Expected a [while], got $(kind(wyle))"
    @assert haschildren(wyle) "A [while] without children! Is this an incomplete tree, from code under edition?"
    condition = children(wyle)[1]
    if kind(condition) == K"Bool" && string(condition) == "true"
        report_violation(condition; severity = SEVERITY, rule_id = RULE_ID,
                                    user_msg = USER_MSG, summary = SUMMARY)
    end
end


end
