module LongFormFunctionsHaveReturnStatement

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Properties: get_func_name, report_violation

function check(_::Nothing)
    # This must have been a weird function definition, if it didn't have a body
end

function check(func_body::SyntaxNode)
    @assert kind(func_body.parent) == K"function" "Expected the body of a [function], got $(kind(func_body))"
    fname = get_func_name(func_body.parent)
    if isnothing(fname) fname = "<invalid>" end
    if kind(func_body) != K"block"
        # It is not the body of a long-form function. No check.
        return nothing
    end
    if !_ends_with_return(func_body)
        last_expr = children(func_body)[end]
        report_violation(last_expr; severity=3,
                rule_id="asml-long-form-functions-have-a-terminating-return-statement",
                user_msg= "Function '$fname' should end with an explicit return statement (or one in each conditional branch).",
                summary="Long form functions are ended by a return statement.")
    end
end

function _ends_with_return(node::SyntaxNode)::Bool
    last_expr = children(node)[end]
    if kind(last_expr) == K"return"
        return true
    elseif kind(last_expr) == K"if"
        # Each branch of the 'if' is a [block] (the first child is not a branch,
        # but the condition)
        return all(_ends_with_return, children(last_expr)[2:end])
    else
        return false
    end
end

end
