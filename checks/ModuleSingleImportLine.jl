module ModuleSingleImportLine

include("_common.jl")
using ...Properties: get_imported_pkg, is_import, is_include, is_module

using Unicode

struct Check<:Analysis.Check end
Analysis.id(::Check) = "module-single-import-line"
Analysis.severity(::Check) = 9
Analysis.synopsis(::Check) = "The list of packages should be in alphabetical order"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_module, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, module_node::SyntaxNode)::Nothing
    @assert kind(module_node) == K"module" "Expected a [module] node, got [$(kind(module_node))]."
    @assert numchildren(module_node) == 2 "This module has a weird shape: " * string(module_node)
    @assert kind(children(module_node)[2]) == K"block" "The second child of a [module] node is not a [block]!"

    # Filters on using, import, include.
    imports = filter(is_import, children(children(module_node)[2]))

    _check_multiple_imports_on_line(this, ctxt, imports)

    # Check imports/usings
    _check_ordering(this, ctxt, imports, node -> !is_include(node) && numchildren(node) <= 1)

    # Check includes
    _check_ordering(this, ctxt, imports, is_include)
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


function _check_ordering(
    this::Check,
    ctxt::AnalysisContext,
    imports::Vector{SyntaxNode},
    predicate::Function
)::Nothing
    previous = ""
    for node in filter(predicate, imports)
        pkg_name_normalized = Unicode.normalize(get_imported_pkg(node), casefold=true)
        if pkg_name_normalized < previous
            report_violation(ctxt, this, node, synopsis(this))
            return nothing
        end

        previous = pkg_name_normalized
    end
    return nothing
end

end # module ModuleSingleImportLine
