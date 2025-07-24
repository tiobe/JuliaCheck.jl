module IndentationLevelsAreFourSpaces

import JuliaSyntax: @K_str, kind
using ...Checks: is_enabled
using ...Properties: lines_count, report_violation
using ...LosslessTrees: LosslessNode, get_source_text, get_start_coordinates,
                        start_index

const SEVERITY = 7
const RULE_ID = "indentation-levels-are-four-spaces"
const USER_MSG = "Indentation levels are four spaces."
const SUMMARY = "Indentation will be done in multiples of four spaces."

function check(node::LosslessNode)
    if !is_enabled(RULE_ID) return nothing end

    # We will inspect nodes of kind [NewlineWs] containing indentation spaces
    # and possibly (most of the time, in fact) starting with a line break, but
    # not ending with one.
    if kind(node) != K"NewlineWs" return nothing end
    textual = get_source_text(node)
    if endswith(textual, '\n') return nothing end
    # That latter case is most likely that the last thing in the file is a
    # keyword (probably [end]) followed by some blanks and a line break.

    indenttext = chomp(reverse(textual))
    # Tabs are flagged by another rule. To prevent double report, account for
    # their presence here, counting 4-1 extra spaces for each tab.
    indentation = length(indenttext) + 3 * count(r"\t", indenttext)
    if rem(indentation, 4) > 0
        report_violation(node;
                         severity = SEVERITY, rule_id = RULE_ID,
                         user_msg = USER_MSG, summary = SUMMARY)
    end
end


end
