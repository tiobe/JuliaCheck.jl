module ModuleExportLocation

include("_common.jl")

using ...Properties: is_export, is_import, is_module

struct Check<:Analysis.Check end
Analysis.id(::Check) = "module-export-location"
Analysis.severity(::Check) = 9
Analysis.synopsis(::Check) = "Exports should be implemented after the include instructions"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_module, n -> _check(this, ctxt, n))
    return nothing
end

_no_ex_imports(node::SyntaxNode) = ! (is_import(node) || is_export(node))

function _check(this::Check, ctxt::AnalysisContext, modjule::SyntaxNode)::Nothing
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(modjule))]."
    @assert numchildren(modjule) == 2 "This module has a weird shape: "* string(modjule)
    @assert kind(children(modjule)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    mod_body = children(children(modjule)[2])
    last_export = findlast(is_export, mod_body)
    if isnothing(last_export) return nothing end

    code_begin = findfirst(_no_ex_imports, mod_body)
    if isnothing(code_begin)
        # Nothing to check that is not yet covered by other rules.
        return nothing
    end

    for node in filter(is_export, mod_body[code_begin:end])
        report_violation(ctxt, this, node, synopsis(this))
    end
    return nothing
end

end # module ModuleExportLocation
