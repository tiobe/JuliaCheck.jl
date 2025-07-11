module LocationOfGlobalVariables

import JuliaSyntax: SyntaxNode, @K_str, @KSet_str, children, numchildren, kind
using ...Checks: is_enabled
using ...Properties: haschildren, is_export, is_global_decl, is_import, is_include,
                is_mod_toplevel, is_upper_camel_case, report_violation

const SEVERITY = 7
const RULE_ID = "location-of-global-variables"
const USER_MSG = "Global variables should be placed at the top of a module or file."
const SUMMARY = USER_MSG

function check(glob_decl::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert is_global_decl(glob_decl) "Expected a global declaration node, got $(kind(glob_decl))"
    toplevel = glob_decl.parent
    if !is_mod_toplevel(toplevel)
        # If the global declaration is not at the top level of a module, we
        # don't check it.
        return nothing
    end
    for node in children(toplevel)
        if node === glob_decl
            return nothing  # we are done
        end
        if ! (is_import(node) || is_export(node) || is_global_decl(node))
            # If we find a node that is not an import, export or global
            # declaration between the start of the module and the global
            # declaration under study, we report a violation.
            report_violation(glob_decl; severity = SEVERITY, rule_id = RULE_ID,
                                        user_msg = USER_MSG, summary = SUMMARY)
            return nothing
        end
    end
    return nothing
end

end
