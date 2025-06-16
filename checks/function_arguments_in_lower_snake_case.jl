module FunctionArgumentsInLowerSnakeCase

import JuliaSyntax: SyntaxNode, @K_str, kind, children, numchildren
using ...Properties: find_first_of_kind, is_lower_snake, report_violation

SEVERITY = 7
RULE_ID = "function-arguments-lower-snake-case"
USER_MSG = "Argument must be written in \"lower_snake_case\"."
SUMMARY = "Function arguments are written in \"lower_snake_case\"."

function check(f_name::SyntaxNode, f_arg::SyntaxNode)
    @assert kind(f_name) == K"Identifier" "Expected argument 'f_name' to be an [Identifier], not $(kind(f_name))"

    if kind(f_arg) == K"::"
        f_arg = numchildren(f_arg) == 1 ? nothing : children(f_arg)[1]
    end
    if f_arg !== nothing
        f_arg = find_first_of_kind(K"Identifier", f_arg)
    end
    if isnothing(f_arg)
        # Nothing to check; maybe a ::Val or ::Type, or perhaps a semicolon
        # followed by nothing at all (nasty)
        return nothing
    end
    arg_name = string(f_arg)
    if ! is_lower_snake(arg_name)
        report_violation(f_arg; severity = SEVERITY, rule_id = RULE_ID,
                user_msg = "Argument '$arg_name' of function '$f_name' must be written in \"lower_snake_case\".", # TODO #36595
                summary = SUMMARY)
    end
end


end
