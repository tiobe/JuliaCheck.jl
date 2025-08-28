module ModuleExportLocation

include("_common.jl")

using ...Properties: is_export, is_import, is_module

struct Check<:Analysis.Check end
id(::Check) = "module-export-location"
severity(::Check) = 9
synopsis(::Check) = "Exports should be implemented after the include instructions"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_module, n -> check(this, ctxt, n))
end

no_ex_imports(node::SyntaxNode) = ! (is_import(node) || is_export(node))

function check(this::Check, ctxt::AnalysisContext, modjule::SyntaxNode)
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(modjule))]."
    @assert numchildren(modjule) == 2 "This module has a weird shape: "* string(modjule)
    @assert kind(children(modjule)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    mod_body = children(children(modjule)[2])
    last_export = findlast(is_export, mod_body)
    if last_export === nothing return nothing end

    code_begin = findfirst(no_ex_imports, mod_body)
    if code_begin === nothing
        # Nothing to check that is not yet covered by other rules.
        return nothing
    end

    for node in filter(is_export, mod_body[code_begin:end])
        report_violation(ctxt, this, node, synopsis(this))
    end
end

end # module ModuleExportLocation
