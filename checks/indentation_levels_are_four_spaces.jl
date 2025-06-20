module IndentationLevelsAreFourSpaces

import JuliaSyntax: GreenNode, SourceFile, @K_str, kind, children, span
using ...Checks: is_enabled
using ...Properties: lines_count, report_violation, source_index, source_text

SEVERITY = 7
RULE_ID = "asml-indentation-levels-are-four-spaces"
USER_MSG = "Indentation levels are four spaces."
SUMMARY = "Indentation will be done in multiples of four spaces."

function check(node::GreenNode)
    if !is_enabled(RULE_ID) return nothing end

    # We will inspect nodes of kind [NewlineWs] containing indentation spaces
    # and possibly (most of the time, in fact) starting with a line break, but
    # not ending with one.
    if kind(node) != K"NewlineWs" return nothing end
    textual = source_text(node)
    if endswith(textual, '\n') return nothing end
    # That latter case is most likely that the last thing in the file is a
    # keyword (probably [end]) followed by some blanks and a line break.

    indenttext = chomp(reverse(textual))
    # Tabs are flagged by another rule. To prevent double report, account for
    # their presence here, counting 4-1 extra spaces for each tab.
    indentation = length(indenttext) + 3 * count(r"\t", indenttext)
    if rem(indentation, 4) > 0
        report_violation(index=source_index()+1, len=indentation,
                         line=lines_count()+1, col=1,
                         severity = SEVERITY, rule_id = RULE_ID,
                         user_msg = USER_MSG, summary = SUMMARY)
    end
end


end
