module FunctionIdentifiersCasing

import JuliaSyntax: SyntaxNode, @K_str, kind
using ...Properties: is_lower_snake, report_violation

function check(func_name::SyntaxNode)
    @assert kind(func_name) == K"Identifier" "Expected an [Identifier] node, got [$(kind(node))]."
    fname = string(func_name)
    if ! is_lower_snake(fname)
        report_violation(func_name, 8;
                         user_msg="Function name `$fname` should be written in lower_snake_case.",
                         summary="Function names are written in lower_snake_case.")
    end
end

end
