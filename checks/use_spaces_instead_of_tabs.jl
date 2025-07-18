module UseSpacesInsteadOfTabs

using JuliaSyntax: @K_str, kind
using ...Checks: is_enabled
using ...Properties: report_violation
using ...LosslessTrees: LosslessNode, get_source_text

const SEVERITY = 7
const RULE_ID = "use-spaces-instead-of-tabs"
const SUMMARY = "Use spaces instead of tabs for indentation."
const USER_MSG = SUMMARY

function check(node::LosslessNode)
    if !is_enabled(RULE_ID) return nothing end

    if kind(node) == K"NewlineWs"   # otherwise, it wouldn't be indentation
        match = findfirst('\t', get_source_text(node))
        if match !== nothing
            # For a string like "\n\t", `match` would be 2, which is a delta=0
            report_violation(node; delta = match - 2,
                                   severity = SEVERITY, rule_id = RULE_ID,
                                   user_msg = USER_MSG, summary = SUMMARY)
        end
    end
end

end
