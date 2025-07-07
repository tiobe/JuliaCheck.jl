module UseIsmissingToCheckForMissingValues

import JuliaSyntax: SyntaxNode, GreenNode, @K_str, @KSet_str, children, kind,
                numchildren, span, untokenize
using ...Checks: is_enabled
using ...Properties: NullableString, find_lhs_of_kind, numchildren,
                haschildren, report_violation

const SEVERITY = 3
const RULE_ID = "use-ismissing-to-check-for-missing-values"
const USER_MSG = "Use ismissing to check for missing values."
const SUMMARY = "Use ismissing to check for missing values."

"""
    check(node::SyntaxNode)

Report if a check for missing value is done by direct comparison.
"""
function check(node::SyntaxNode)::Nothing
    if !is_enabled(RULE_ID) return nothing end

    missing_type = extract_missing_type(node)
    if missing_type !== nothing
        report_violation(node; severity = SEVERITY, rule_id = RULE_ID,
                               user_msg = USER_MSG, summary = SUMMARY)
    end
end

function extract_missing_type(node::SyntaxNode)::NullableString
    if kind(node) == K"." && length(children(node)) >= 2
        # For qualified names like Base.Inf, return just the Inf part
        node = last(children(node))
    end

    if kind(node) == K"Identifier" && string(node) ∈ ("Missing", "missing")
        return string(node)
    end

    return nothing
end


end # module UseIsmissingToCheckForMissingValues
