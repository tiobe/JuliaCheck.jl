module ModuleImportLocation

include("_common.jl")

using ...Properties: is_import, is_include, is_module

struct Check<:Analysis.Check end
id(::Check) = "module-import-location"
severity(::Check) = 9
synopsis(::Check) = "Packages should be imported after the module keyword."

const USER_MSG = "Move imports to the top of the module, before any actual code"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_module, n -> check(this, ctxt, n))
end

function check(this::Check, ctxt::AnalysisContext, modjule::SyntaxNode)::Nothing
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
                report_violation(ctxt, this, node, USER_MSG)
            end
        end
    end
    return nothing
end

end # module ModuleImportLocation
