module DoNotSetVariablesToNan

import JuliaSyntax: SyntaxNode, GreenNode, @K_str, @KSet_str, children, kind,
                span, untokenize
using ...Checks: is_enabled
using ...Properties: find_lhs_of_kind, get_assignee, haschildren,
                report_violation

const SEVERITY = 3
const RULE_ID = "do-not-set-variables-to-nan"
const USER_MSG = "Do not set variables to NaN."
const SUMMARY = "Do not set variables to NaN, NaN16, NaN32 or NaN64"


function check(node::SyntaxNode)::Nothing
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(node) == K"=" "Expected an assignment [=] node, got $(kind(node))."
    # Assignment should have exactly 2 children: lhs and rhs

    if length(children(node)) != 2
        @debug "Assignment with $(length(children(node))) children instead of 2."
        return nothing
    end
    rhs = children(node)[2]
    # Check if right-hand side is a NaN value
    if is_nan_value(rhs)
        # TODO #36595 nan_type = extract_nan_type(rhs)
        report_violation(rhs; severity = SEVERITY, rule_id = RULE_ID,
                              user_msg = USER_MSG, summary = SUMMARY)
    end
end


function is_nan_value(node::SyntaxNode)::Bool
    NaNs = ("NaN", "NaN16", "NaN32", "NaN64")
    # TODO this won't detect all sorts of NaN, such as `Inf - Inf`. A possibility
    # is to evaluate the expression in a try/catch block and check if it is of
    # NaN type.

    # Check if it's an identifier
    if kind(node) == K"Identifier"
        identifier_text = string(node)
        return identifier_text in NaNs
    end
    
    # Check if it's a qualified name like Base.NaN
    if kind(node) == K"."
        if length(children(node)) >= 2
            # Get the last part of the qualified name
            last_part = last(children(node))
            if kind(last_part) == K"Identifier"
                identifier_text = string(last_part)
                return identifier_text in NaNs
            end
        end
    end
    
    return false
end

function extract_nan_type(node::SyntaxNode)::String
    if kind(node) == K"Identifier"
        return string(node)
    elseif kind(node) == K"."
        # For qualified names like Base.NaN, return just the NaN part
        if length(children(node)) >= 2
            last_part = last(children(node))
            if kind(last_part) == K"Identifier"
                return string(last_part)
            end
        end
    end
    @debug "Unexpected shape of an assigned value (RHS)" node
    return ""
end


end # module DoNotSetVariablesToNan
