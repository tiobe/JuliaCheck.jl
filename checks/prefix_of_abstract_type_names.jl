module PrefixOfAbstractTypeNames

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Checks: is_enabled
using ...Properties: find_lhs_of_kind, is_upper_camel_case, report_violation

const SEVERITY = 4
const RULE_ID = "asml-prefix-of-abstract-type-names"
const SUMMARY = USER_MSG = "Abstract type names are prefixed by \"Abstract\"."

function check(user_type::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(user_type) == K"abstract"  "Expected an [abstract] node, got $(kind(user_type))"
    type_id = find_lhs_of_kind(K"Identifier", user_type)
    @assert type_id !== nothing "Got a type declaration without name (identifier)."
    type_name = string(type_id)
    if is_enabled("type-names-upper-camel-case") && ! is_upper_camel_case(type_name)
        report_violation(type_id; severity=3,
                rule_id="type-names-upper-camel-case",
                user_msg="Type names such as $type_name should be written in UpperCamelCase.", # TODO CHECK_REGISTRY[rule_id].user_msg
                summary="Type names in UpperCamelCase.")
    end
    if ! startswith(type_name, "Abstract")
        report_violation(type_id; severity = SEVERITY, rule_id = RULE_ID,
                         user_msg = "Abstract type names like $type_name should have prefix \"Abstract\".", # TODO #36595
                         summary = SUMMARY)
    end
end

end
