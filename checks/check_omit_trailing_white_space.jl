module OmitTrailingWhiteSpace

import JuliaSyntax: GreenNode, @K_str, @KSet_str, kind
using ...Properties: lines_count, report_violation, source_index, source_text

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
        report_violation(index=source_index()+offset, len=span,
                         line=lines_count()+1, col=1,
                         severity=7, rule_id="asml-omit-trailing-white-space",
                         user_msg="Omit spaces at the end of a line.",
                         summary="Omit trailing whitespace.")
    end
end


end
