module UseSpacesInsteadOfTabs

import JuliaSyntax: GreenNode, SourceFile, @K_str, kind, children, span
using ...Checks: is_enabled
using ...Properties: lines_count, report_violation, source_index, source_text

const SEVERITY = 7
const RULE_ID = "use-spaces-instead-of-tabs"
const USER_MSG = "There are tab characters here."
const SUMMARY = "Use spaces instead of tabs for indentation."

function check(node::GreenNode)
    if !is_enabled(RULE_ID) return nothing end

    if kind(node) != K"NewlineWs"
        return nothing
    end
    textual = source_text(node)
    match = findfirst("\t", textual)
    if match !== nothing
        report_violation(index = source_index() + match.start - 1, len = 1,
                        line = lines_count() + 1, col = match.start - 1,
                        severity = SEVERITY, rule_id = RULE_ID,
                        user_msg = USER_MSG, summary = SUMMARY)
    end
end


end
