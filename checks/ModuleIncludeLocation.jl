module ModuleIncludeLocation

using ...Properties: get_imported_pkg, is_import, is_include, is_module

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "module-include-location"
Analysis.severity(::Check) = 9
Analysis.synopsis(::Check) = "The list of included files should be after the list of imported packages"

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_module, n -> _check(this, ctxt, n))
end

function _check(this::Check, ctxt::AnalysisContext, modjule::SyntaxNode)::Nothing
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(modjule))]."
    @assert numchildren(modjule) == 2 "This module has a weird shape: "* string(modjule)
    @assert kind(children(modjule)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    mod_body = children(children(modjule)[2])
    code_beginning = findfirst(!is_import, mod_body)
    if isnothing(code_beginning)
        # No code, only imports. It usually happens in packages "entry" files.
        code_beginning = length(mod_body) + 1
    end
    includes_start = findfirst(is_include, mod_body[1:code_beginning-1])
    if ! isnothing(includes_start)
        for (i, node) in enumerate(mod_body[includes_start+1 : code_beginning-1])
            if !is_include(node)
                # It must be an [import] or [using]
                previous = mod_body[includes_start + i - 1]
                imported_module = get_imported_pkg(node)
                included_pkg = get_imported_pkg(previous)
                if !is_include(previous) || imported_module != included_pkg
                    report_violation(ctxt, this, node, synopsis(this))
                end
            end
        end
    end
    return nothing
end

end # module ModuleIncludeLocation

