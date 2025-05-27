module ModuleSingleImportLine

import JuliaSyntax: SyntaxNode, @K_str, @KSet_str, children, numchildren, kind
using ...Properties: get_imported_pkg, haschildren, is_import, is_include,
                is_upper_camel_case, report_violation

function check(modjule::SyntaxNode)
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(node))]."
    @assert numchildren(modjule) == 2 "This module has a weird shape: "* string(modjule)
    @assert kind(children(modjule)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    imports = filter(is_import, children(children(modjule)[2]))
    previous = ""
    for node in filter(!is_include, imports)
        if numchildren(node) > 1
            report_violation(node;
                severity=9, rule_id="asml-module-single-import-line",
                user_msg="Import only one package per line.",
                summary="Lists of imported/used packages should only specify a single package per line.")
        else
            pkg = get_imported_pkg(node)
            pkg_name = string(pkg)
            if pkg_name < previous
                report_violation(pkg;
                    severity=9, rule_id="asml-module-single-import-line",
                    user_msg="Keep import/using declarations in alphabetic order.",
                    summary="The list of packages should be in alphabetic order.")
            else
                previous = pkg_name
            end
        end
    end
end


end
