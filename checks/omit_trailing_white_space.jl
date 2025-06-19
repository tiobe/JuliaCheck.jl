module OmitTrailingWhiteSpace

import JuliaSyntax: GreenNode, @K_str, @KSet_str, kind
using ...Properties: lines_count, report_violation, source_index, source_text

SEVERITY = 7
RULE_ID = "asml-omit-trailing-white-space"
USER_MSG = "Omit spaces at the end of a line."
SUMMARY = "Omit trailing whitespace."

function check(node::GreenNode)
    if kind(node) ∉ KSet"NewlineWs String" return nothing end
    textual = source_text(node)
    found = match(r"( +)\n", textual)
    if found !== nothing
        span = length(found.captures[1])
        offset = 0
        if kind(node) == K"String"
            offset = length(textual) - span - (Sys.iswindows() ? 2 : 1)
        end
        report_violation(index = source_index() + offset, len = span,
                         line = lines_count() + 1, col = 1,
                         severity = SEVERITY, rule_id = RULE_ID,
                         user_msg = USER_MSG, summary = SUMMARY)
    end
end


end
