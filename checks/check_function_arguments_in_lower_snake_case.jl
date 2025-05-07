module FunctionArgumentsCasing

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Properties: is_lower_snake, report_violation

function check(f_name::SyntaxNode, f_arg::SyntaxNode)
    @assert kind(f_name) == K"Identifier" "Expected argument 'f_name' to be an [Identifier], not $(kind(f_name))"
    while kind(f_arg) != K"Identifier"
        f_arg = children(f_arg)[1]
    end
    arg_name = string(f_arg)
    if ! is_lower_snake(arg_name)
        report_violation(f_arg, 7;
                         user_msg="Argument '$arg_name' of function '$f_name' must be written in \"lower_snake_case\".",
                         summary="Function arguments are written in lower_snake_case.")
    end
end


end
