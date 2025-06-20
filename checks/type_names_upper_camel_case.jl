module TypeNamesUpperCamelCase

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Checks: is_enabled
using ...Properties: find_first_of_kind, is_upper_camel_case, report_violation

SEVERITY = 3
RULE_ID = "asml-type-names-upper-camel-case"
# TODO #36595
USER_MSG = SUMMARY = "Type names in \"UpperCamelCase\"."

function check(user_type::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(user_type) == K"struct"  "Expected a [struct] node, got $(kind(user_type))"
    type_name = find_first_of_kind(K"Identifier", user_type)
    if ! is_upper_camel_case(string(type_name))
        report_violation(type_name;
            severity = SEVERITY, rule_id = RULE_ID, summary = SUMMARY,
            user_msg = "Type names such as $(string(type_name)) should be written in \"UpperCamelCase\".")
    end
end

end
