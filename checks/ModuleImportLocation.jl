module ModuleImportLocation

include("_common.jl")

using ...Properties: is_import, is_include, is_module

struct Check<:Analysis.Check end
Analysis.id(::Check) = "module-import-location"
Analysis.severity(::Check) = 9
function Analysis.synopsis(::Check)
    return "Packages should be imported after the module keyword."
end

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_module, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, modjule::SyntaxNode)::Nothing
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(node))]."
    @assert numchildren(modjule) == 2 "This module has a weird shape: " * string(modjule)
    @assert kind(children(modjule)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    mod_body = children(children(modjule)[2])
    code_starts_here = findfirst(!is_import, mod_body)
    if ! isnothing(code_starts_here)
        for node in mod_body[code_starts_here:end]
            if is_import(node) && !is_include(node)
                # We can skip include's because they are followed by an import
                # or a using (we made sure in 'is_import').
                report_violation(ctxt, this, node,
                    "Move imports to the top of the module, before any actual code"
                    )
            end
        end
    end
    return nothing
end

end # module ModuleImportLocation
