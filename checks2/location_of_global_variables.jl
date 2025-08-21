module LocationOfGlobalVariables

include("_common.jl")

using ...Properties: haschildren, is_export, is_global_decl, is_import, is_mod_toplevel

struct Check <: Analysis.Check end
id(::Check) = "location-of-global-variables"
severity(::Check) = 7
synopsis(::Check) = "Global variables should be placed at the top of a module or file"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_global_decl, n -> check(this, ctxt, n))
end

function check(this::Check, ctxt::AnalysisContext, glob_decl::SyntaxNode)

    @assert is_global_decl(glob_decl) "Expected a global declaration node, got $(kind(glob_decl))"
    toplevel = glob_decl.parent
    if !is_mod_toplevel(toplevel)
        # If the global declaration is not at the top level of a module, we
        # don't check it.
        return
    end
    for node in children(toplevel)
        if node === glob_decl
            return # we are done
        end
        if ! (is_import(node) || is_export(node) || is_global_decl(node))
            # If we find a node that is not an import, export or global
            # declaration between the start of the module and the global
            # declaration under study, we report a violation.
            report_violation(ctxt, this, glob_decl, synopsis(this))
            return
        end
    end
    return
end

end
