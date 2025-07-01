module FunctionIdentifiersInLowerSnakeCase

import JuliaSyntax: SyntaxNode, @K_str, kind
using ...Checks: is_enabled
using ...Properties: inside, is_lower_snake, is_struct, report_violation

const SEVERITY = 8
const RULE_ID = "asml-function-identifiers-in-lower-snake-case"
const USER_MSG = "Function name should be written in \"lower_snake_case\"."
const SUMMARY = "Function names are written in lower_snake_case."

function check(func_name::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(func_name) == K"Identifier" "Expected an [Identifier] node, got [$(kind(node))]."
    if inside(func_name, is_struct)
        # Inner constructors (functions inside a type definition) must match the
        # type's name, which must follow a different naming convention than
        # functions do, so they are excluded from this check.
        return nothing
    end
    fname = string(func_name)
    if ! is_lower_snake(fname)
        report_violation(func_name; severity = SEVERITY, rule_id = RULE_ID,
                user_msg = "Function name $fname should be written in lower_snake_case.", # TODO #36595
                summary = SUMMARY)
    end
end

end
