module ModuleSingleImportLine

include("_common.jl")
using ...Properties: get_imported_pkg, is_import, is_include, is_module

struct Check <: Analysis.Check end
id(::Check) = "module-single-import-line"
severity(::Check) = 9
synopsis(::Check) = "The list of packages should be in alphabetic order"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_module, n -> check(this, ctxt, n))
end


function check(this::Check, ctxt::AnalysisContext, modjule::SyntaxNode)
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(modjule))]."
    @assert numchildren(modjule) == 2 "This module has a weird shape: "* string(modjule)
    @assert kind(children(modjule)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    imports = filter(is_import, children(children(modjule)[2]))
    first_include = findfirst(is_include, imports)
    if isnothing(first_include) first_include = 1 + length(imports) end

    # First, check import's and using's (they are supposed to be contiguous, or
    # else they violate another rule)
    previous = ""
    for node in imports[1 : first_include-1]
        if numchildren(node) > 1
            report_violation(ctxt, this, node, "Import only one package per line.")
        else
            pkg_name = get_imported_pkg(node)
            if pkg_name < previous
                report_violation(ctxt, this, node, synopsis(this))
            else
                previous = pkg_name
            end
        end
    end

    # Now, we check the include's. Only their sorting (cannot include multiple
    # files at once)
    previous = ""
    for node in filter(is_include, imports[first_include : end])
        pkg_name = get_imported_pkg(node)
        if pkg_name < previous
            report_violation(ctxt, this, node, synopsis(this))
        else
            previous = pkg_name
        end
    end
end

end # module ModuleSingleImportLine

