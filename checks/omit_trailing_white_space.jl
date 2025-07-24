module OmitTrailingWhiteSpace

import JuliaSyntax: @K_str, @KSet_str, kind
using ...Checks: is_enabled
using ...Properties: EOL, lines_count, report_violation, source_text
using ...LosslessTrees: LosslessNode, get_source_text, start_index

const SEVERITY = 7
const RULE_ID = "omit-trailing-white-space"
const USER_MSG = "Omit spaces at the end of a line."
const SUMMARY = "Omit trailing whitespace."

function check(node::LosslessNode)
    if !is_enabled(RULE_ID) return nothing end

    if kind(node) ∉ KSet"NewlineWs String" return nothing end
    textual = get_source_text(node)
    found = match(r"( +)\n", textual)
    # if endswith(textual, ' ')
    if found !== nothing
        span = length(found.captures[1])
        offset = 0
        if kind(node) == K"String"
            offset = length(textual) - span - length(EOL)
        end
        report_violation(node; delta = offset,
                         severity = SEVERITY, rule_id = RULE_ID,
                         user_msg = USER_MSG, summary = SUMMARY)
    end
end


end
