module UseIsnothingToCheckForNothingValues

import JuliaSyntax: SyntaxNode, GreenNode, @K_str, @KSet_str, children, kind,
                numchildren, span, untokenize
using ...Checks: is_enabled
using ...Properties: NullableString, find_first_of_kind, get_assignee,
                haschildren, report_violation

const SEVERITY = 3
const RULE_ID = "asml-use-isnothing-to-check-for-nothing-values"
const USER_MSG = "Use isnothing to check for nothing values."
const SUMMARY = "Use isnothing to check variables for nothing."

"""
    check(node::SyntaxNode)

Report if a check for nothing is done by direct comparison.
"""
function check(node::SyntaxNode)::Nothing
    if !is_enabled(RULE_ID) return nothing end

    nothing_type = extract_nothing_type(node)
    if nothing_type !== nothing
        report_violation(node; severity = SEVERITY, rule_id = RULE_ID,
                               user_msg = USER_MSG, summary = SUMMARY)
    end
end

function extract_nothing_type(node::SyntaxNode)::NullableString
    if kind(node) == K"." && length(children(node)) >= 2
        # For qualified names like Base.nothing, return just the nothing part
        node = last(children(node))
    end

    if kind(node) == K"Identifier" && string(node) ∈ ("nothing","Nothing")
        return string(node)
    end

    return nothing
end


end # module UseIsnothingToCheckForNothingValues
