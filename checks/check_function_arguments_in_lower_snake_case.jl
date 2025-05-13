module FunctionArgumentsCasing

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Properties: find_first_of_kind, is_lower_snake, report_violation

function check(f_name::SyntaxNode, f_arg::SyntaxNode)
    @assert kind(f_name) == K"Identifier" "Expected argument 'f_name' to be an [Identifier], not $(kind(f_name))"
    f_arg = find_first_of_kind(K"Identifier", f_arg)
    if isnothing(f_arg)
        # Nothing to check; probably a semicolon followed by nothing at all (nasty)
        return nothing
    end
    arg_name = string(f_arg)
    if ! is_lower_snake(arg_name)
        report_violation(f_arg; severity=7,
                rule_id="asml-function-arguments-lower-snake-case",
                user_msg="Argument '$arg_name' of function '$f_name' must be written in \"lower_snake_case\".",
                summary="Function arguments are written in lower_snake_case.")
    end
end


end
