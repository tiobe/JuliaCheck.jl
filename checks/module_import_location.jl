module ModuleImportLocation

import JuliaSyntax: SyntaxNode, @K_str, @KSet_str, children, numchildren, kind
using ...Checks: is_enabled
using ...Properties: haschildren, is_import, is_include, is_upper_camel_case,
                report_violation

const SEVERITY = 9
const RULE_ID = "asml-module-import-location"
const USER_MSG = "Move imports to the top of the module, before any actual code."
const SUMMARY = "Packages should be imported after the module keyword."

function check(modjule::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(node))]."
    @assert numchildren(modjule) == 2 "This module has a weird shape: "* string(modjule)
    @assert kind(children(modjule)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    mod_body = children(children(modjule)[2])
    code_starts_here = findfirst(!is_import, mod_body)
    if code_starts_here !== nothing
        for node in mod_body[code_starts_here:end]
            if is_import(node) && !is_include(node)
                # We can skip include's because they are followed by an import
                # or a using (we made sure in 'is_import').
                report_violation(node; severity = SEVERITY, rule_id = RULE_ID,
                                       user_msg = USER_MSG, summary = SUMMARY)
            end
        end
    end
end


end
