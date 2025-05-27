module ModuleSingleImportLine

import JuliaSyntax: SyntaxNode, @K_str, @KSet_str, children, numchildren, kind
using ...Properties: haschildren, is_import, is_include, is_upper_camel_case,
                report_violation

function check(modjule::SyntaxNode)
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(node))]."
    @assert numchildren(modjule) == 2 "This module has a weird shape: "* string(modjule)
    @assert kind(children(modjule)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    imports = filter(is_import, children(children(modjule)[2]))
    for node in filter(!is_include, imports)
        if numchildren(node) > 1
            report_violation(node;
                severity=9, rule_id="asml-module-single-import-line",
                user_msg="Import only one package per line.",
                summary="Lists of imported/used packages should only specify a single package per line.")
        end
    end
end


end
