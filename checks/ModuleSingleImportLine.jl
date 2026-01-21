module ModuleSingleImportLine

include("_common.jl")
using ...Properties: get_imported_pkg, is_import, is_include, is_module

struct Check<:Analysis.Check end
id(::Check) = "module-single-import-line"
severity(::Check) = 9
synopsis(::Check) = "The list of packages should be in alphabetical order"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_module, n -> check(this, ctxt, n))
end

function check(this::Check, ctxt::AnalysisContext, module_node::SyntaxNode)::Nothing
    @assert kind(module_node) == K"module" "Expected a [module] node, got [$(kind(module_node))]."
    @assert numchildren(module_node) == 2 "This module has a weird shape: "* string(module_node)
    @assert kind(children(module_node)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    # Filters on using, import, include.
    imports = filter(is_import, children(children(module_node)[2]))

    _check_multiple_imports_on_line(this, ctxt, imports)
    _check_import_ordering(this, ctxt, imports)
    _check_include_ordering(this, ctxt, imports)
    return nothing
end

function _check_multiple_imports_on_line(this::Check, ctxt::AnalysisContext, imports::Vector{SyntaxNode})::Nothing
    for node in filter(!is_include, imports)
        if numchildren(node) > 1
            report_violation(ctxt, this, node, "Import only one package per line.")
        end
    end
    return nothing
end

function _check_import_ordering(this::Check, ctxt::AnalysisContext, imports::Vector{SyntaxNode})::Nothing
    previous = ""
    for node in filter(!is_include, imports)
        pkg_name = get_imported_pkg(node)
        if numchildren(node) <= 1
            if pkg_name < previous
                report_violation(ctxt, this, node, synopsis(this))
                return nothing
            else
                previous = pkg_name
            end
        end
    end
    return nothing
end

function _check_include_ordering(this::Check, ctxt::AnalysisContext, imports::Vector{SyntaxNode})::Nothing
    previous = ""
    for node in filter(is_include, imports)
        pkg_name = get_imported_pkg(node)
        if pkg_name < previous
            report_violation(ctxt, this, node, synopsis(this))
            return nothing
        else
            previous = pkg_name
        end
    end
    return nothing
end

end # module ModuleSingleImportLine
