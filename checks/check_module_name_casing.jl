module ModuleNameCasing

import JuliaSyntax: SyntaxNode, @K_str, children, kind
using ...Properties: haschildren, is_upper_camel_case, report_violation

function check(modjule::SyntaxNode)
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(node))]."
    @assert haschildren(modjule) "An empty module with no name?"
    mod_id = children(modjule)[1]
    if kind(mod_id) != K"Identifier"
        @debug "The first child of a [module] node is not its identifier!" mod_id
        return nothing
    end
    name = string(mod_id)
    if ! is_upper_camel_case(name)
        report_violation(mod_id; severity=5, rule_id="asml-module-name-casing",
                user_msg="Module name `$name` should be written in UpperCamelCase.",
                summary="Package and module names should be written in UpperCamelCase.")
    end
end

end
