module AvoidExtraneousWhitespaceBetweenOpenAndCloseCharacters

import JuliaSyntax: @K_str, is_whitespace, kind, span
using ...Checks: is_enabled
using ...Properties: is_array_indx, is_array_init, report_violation
using ...LosslessTrees: LosslessNode, children

const SEVERITY = 7
const RULE_ID = "avoid-extraneous-whitespace-between-open-and-close-characters"
const USER_MSG = "Avoid extraneous whitespace inside parentheses, square brackets or braces."
const SUMMARY = USER_MSG

function check(node::LosslessNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert is_array_indx(node) || is_array_init(node) "Expected something that comes in square brackets, got [$(kind(node))]."

    if is_array_indx(node)
        # The first child of this node is the identifier of the indexed array
        bracketted = children(node)[2:end]
    else
        bracketted = children(node)
    end
    if !( kind(bracketted[1]) == K"[" && kind(bracketted[end]) == K"]" )
        @debug "I don't understand this [$(kind(node))]:" node.green_node
        return nothing
    end
    from = 2
    until = length(bracketted) - 1
    if is_whitespace(bracketted[2])
        if kind(bracketted[2]) == K"Whitespace"
            # It's OK if it's a newline after '[', but not whitespace
            report(bracketted[2])
        end
        from = 3
    end
    if is_whitespace(bracketted[end-1])
        if kind(bracketted[end-1]) == K"Whitespace"
            # Same thing before the closing bracket
            report(bracketted[end-1])
        end
        until -= 1
    end
    separators = filter(x -> kind(x) == K"Whitespace", bracketted[from:until])
    for sep in separators
        if span(sep) > 1
            report(sep)
        end
    end
end

function report(node::LosslessNode)
    report_violation(node; severity = SEVERITY, user_msg = USER_MSG,
                           summary = SUMMARY, rule_id = RULE_ID)
end

end
