module FunctionArgumentsLowerSnakeCase

import JuliaSyntax: SyntaxNode, @K_str, kind, children, numchildren
using ...Checks: is_enabled
using ...Properties: find_lhs_of_kind, is_lower_snake, report_violation

const SEVERITY = 7
const RULE_ID = "function-arguments-lower-snake-case"
const USER_MSG = "Argument must be written in \"lower_snake_case\"."
const SUMMARY = "Function arguments are written in \"lower_snake_case\"."

function check(f_name::AbstractString, f_arg::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    if kind(f_arg) == K"::"
        f_arg = numchildren(f_arg) == 1 ? nothing : children(f_arg)[1]
    end
    if f_arg !== nothing
        f_arg = find_lhs_of_kind(K"Identifier", f_arg)
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
