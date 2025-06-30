module LongFormFunctionsHaveATerminatingReturnStatement

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Checks: is_enabled
using ...Properties: inside, is_struct, get_func_name, haschildren, report_violation

const SEVERITY = 3
const RULE_ID = "asml-long-form-functions-have-a-terminating-return-statement"
const USER_MSG = "Long form functions are terminated by an explicit return statement."
const SUMMARY = "Long form functions are ended by a return statement."

function check(_::Nothing)
    # This must have been a weird function definition, if it didn't have a body
    return nothing
end

function check(func_body::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(func_body.parent) == K"function" "Expected the body of a [function], got $(kind(func_body))"
    fname = get_func_name(func_body.parent)
    if isnothing(fname) fname = "<invalid>" end
    if kind(func_body) != K"block" || inside(func_body, is_struct)
        # It is either a short-form function or an inner constructor.
        return nothing
    end
    if !_ends_with_return(func_body)
        node = haschildren(func_body) ? children(func_body)[end] : func_body
        report_violation(node; severity = SEVERITY, rule_id = RULE_ID,
                               user_msg = USER_MSG, summary = SUMMARY)
    end
end

function _ends_with_return(node::SyntaxNode)::Bool
    if ! haschildren(node)
        # Empty block. Odd, but happens. Assuming it should contain "return nothing"
        return false
    end
    last_expr = children(node)[end]
    return if kind(last_expr) == K"if"
            # Each branch of the 'if' is a [block] (the first child is not a branch,
            # but the condition)
            all(_ends_with_return, children(last_expr)[2:end])
        else
            kind(last_expr) == K"return"
        end
end

end
