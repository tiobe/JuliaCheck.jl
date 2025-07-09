module ModuleNameCasing

import JuliaSyntax: SyntaxNode, @K_str, children, kind
using ...Checks: is_enabled
using ...Properties: get_module_name, haschildren, is_upper_camel_case, report_violation

const SEVERITY = 5
const RULE_ID = "module-name-casing"
const USER_MSG = "Package and module names should be written in UpperCamelCase."
const SUMMARY = "Package names and module names."

function check(modjule::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(modjule))]."
    (mod_id_node, mod_id_str) = get_module_name(modjule)
    if ! is_upper_camel_case(mod_id_str)
        report_violation(mod_id_node; severity = SEVERITY, rule_id = RULE_ID,
                                      user_msg = USER_MSG, summary = SUMMARY)
    end
end

end
