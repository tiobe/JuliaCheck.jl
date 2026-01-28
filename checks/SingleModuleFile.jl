module SingleModuleFile

include("_common.jl")
using JuliaSyntax: filename
using ...Properties: is_module

struct Check<:Analysis.Check end
Analysis.id(::Check) = "single-module-file"
Analysis.severity(::Check) = 5
Analysis.synopsis(::Check) = "Single module per file"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_module, node -> _check(this, ctxt, node))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, module_node::SyntaxNode)::Nothing
    @assert kind(module_node) == K"module" "Expected a [module] node, got [$(kind(module_node))]."
    father = module_node.parent
    kids = children(father)
    if kind(father) == K"toplevel"
        mod_id = children(module_node)[1]
        mod_name = string(mod_id)
        file_name = basename(filename(module_node))[1:end-3]
        if mod_name !== file_name
            report_violation(ctxt, this, mod_id,
                    "Module name $mod_id should match its file name: $file_name."
                    )
        end
        if length(kids) > 1
            # This is not a submodule, and it has got siblings, which is bad, since
            # the top-level module should contain the whole of the file's contents.
            modules = filter(is_module, kids)
            if module_node !== modules[1]
                # Everything else below has already been reported
                return nothing
            end
            mod_id = children(modules[1])[1]
            name_1st_mod = string(mod_id)
            for node in modules[2:end]  # all modules but the 1st
                mod_id = children(node)[1]
                mod_name = string(mod_id)
                report_violation(ctxt, this, mod_id,
                        "Module '$mod_name' should be inside '$name_1st_mod' or in its own file."
                        )
            end
        end
    end
    return nothing
end

end # module SingleModuleFile
