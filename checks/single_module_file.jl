module SingleModuleFile

import JuliaSyntax: SyntaxNode, @K_str, children, filename, kind
using ...Checks: is_enabled
using ...Properties: haschildren, is_module, report_violation

const SEVERITY = 5
const RULE_ID = "asml-single-module-file"
const SUMMARY = USER_MSG = "Single module files."

function check(modjule::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(node))]."
    father = modjule.parent
    kids = children(father)
    if kind(father) == K"toplevel"
        mod_id = children(modjule)[1]
        mod_name = string(mod_id)
        file_name = basename(filename(modjule))[1:end-3]
        if mod_name !== file_name
            report_violation(mod_id; severity = SEVERITY, rule_id = RULE_ID,
                    user_msg="Module name $mod_id should match its file name: $file_name.", # TODO #36595
                    summary="A file in which a module is implemented should have the name of the module it contains.")
        end
        if length(kids) > 1
            # This is not a submodule, and it has got siblings, which is bad, since
            # the top-level module should contain the whole of the file's contents.
            modules = filter(is_module, kids)
            if modjule !== modules[1]
                # Everything else below has already been reported
                return nothing
            end
            mod_id = children(modules[1])[1]
            name_1st_mod = string(mod_id)
            for node in modules[2:end]  # all modules but the 1st
                mod_id = children(node)[1]
                mod_name = string(mod_id)
                report_violation(mod_id; severity = SEVERITY, rule_id = RULE_ID,
                        user_msg="Module '$mod_name' should be inside '$name_1st_mod' or in its own file.",
                        summary="Implement a maximum of one module per Julia file.")
            end
            for node in kids[kids .∉ Ref(modules)]
                report_violation(node; severity = SEVERITY, rule_id = RULE_ID,
                        user_msg="Move this code into module '$name_1st_mod'.",
                        summary="All code must be inside a module.")
            end
        end
    end
end

end
