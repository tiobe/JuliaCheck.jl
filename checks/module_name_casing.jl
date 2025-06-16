module ModuleNameCasing

import JuliaSyntax: SyntaxNode, @K_str, children, kind
using ...Properties: get_module_name, haschildren, is_upper_camel_case, report_violation

SEVERITY = 5
RULE_ID = "module-name-casing"
USER_MSG = "Package and module names should be written in UpperCamelCase."
SUMMARY = "Package names and module names."

function check(modjule::SyntaxNode)
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(modjule))]."
    (mod_id_node, mod_id_str) = get_module_name(modjule)
    if ! is_upper_camel_case(mod_id_str)
        report_violation(mod_id_node; severity = SEVERITY, rule_id = RULE_ID,
                                      user_msg = USER_MSG, summary = SUMMARY)
    end
end

end
