module FunctionIdentifiersCasing

import JuliaSyntax: SyntaxNode, @K_str, kind
using ...Properties: is_lower_snake, report_violation

function check(func_name::SyntaxNode)
    @assert kind(func_name) == K"Identifier" "Argument 'fname' should be of type 'Identifier' instead of $(kind(func_name))."
    fname = string(func_name)
    if ! is_lower_snake(fname)
        report_violation(func_name,
                         "Function name `$fname` should be written in lower_snake_case.",
                         "Function names are written in lower_snake_case.")
    end
end

end
