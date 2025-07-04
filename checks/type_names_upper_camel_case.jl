module TypeNamesUpperCamelCase

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Checks: is_enabled
using ...Properties: find_lhs_of_kind, is_upper_camel_case, report_violation

const SEVERITY = 3
const RULE_ID = "asml-type-names-upper-camel-case"
const SUMMARY = USER_MSG = "Type names in \"UpperCamelCase\"."

function check(user_type::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(user_type) == K"Identifier"  "Expected a [Identifier] node, got $(kind(user_type))"
    if ! is_upper_camel_case(string(user_type))
        report_violation(user_type;
            severity = SEVERITY, rule_id = RULE_ID, summary = SUMMARY,
            user_msg = "Type names such as $(string(user_type)) should be written in \"UpperCamelCase\".")
    end
end

end
