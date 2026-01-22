module UnderscorePrefixForPrivateFunctions

include("_common.jl")

using ...Properties: get_func_name, is_export, is_function, is_module

struct Check<:Analysis.Check end
id(::Check) = "underscore-prefix-for-private-functions"
severity(::Check) = 8
synopsis(::Check) = "Private functions are prefixed with one underscore _ character."

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_module, n -> _check(this, ctxt, n))
    return nothing
end

"""
Checks for whether:
    * public functions are correctly exported
    * private functions are correctly not exported

There seem to be two attitudes with regard to writing Julia modules.

One is to have one-module-per-file in the same way as we do here. If it's one-module-per-file,
this rule works just fine as we have all data we need in the tree (since if there's only one
file per module, the export statement is guaranteed to be findable).

Another is the typical idiom as can be seen in JuliaSyntax:

module X

include("file_a.jl")
include("file_b.jl")

export fn_file_a, fn_file_b

end

In that case this rule won't help as currently it is not the intent to check the entire project
(or at least, to track in _which_ module a given source file actually resides). As such, if we
want to support the second case then it's not coverable as of yet. This rule will only be
triggered on a module statement. If there is no module to be found in a file (implying it's either
a script or a part of a different module) this rule will not trigger.
"""
function _check(this::Check, ctxt::AnalysisContext, module_node::SyntaxNode)::Nothing
    module_content_node = children(module_node)[2] # first child is the identifier, second the content
    all_exported_names = _get_exported_function_names(module_content_node)
    for function_node in _get_function_nodes(module_content_node)
        function_name_node = get_func_name(function_node)
        if kind(function_name_node.parent) == K"."
            continue # Do not trigger on extension of a function defined in another module
        end
        if !isnothing(function_name_node)
            function_name = string(function_name_node)
            has_underscore = startswith(function_name, "_")
            if has_underscore && function_name ∈ all_exported_names
                report_violation(ctxt, this, function_name_node,
                    "Exported function $(function_name) starts with an underscore.")
            end
            if !has_underscore && function_name ∉ all_exported_names
                report_violation(ctxt, this, function_name_node,
                    "Non-exported function $(function_name) does not start with an underscore.")
            end
        end
    end
    return nothing
end

function _get_function_nodes(node::SyntaxNode)::Vector{SyntaxNode}
    return filter(is_function, children(node))
end

function _get_exported_function_names(module_node::SyntaxNode)::Set{String}
    exported_names = Set{String}()
    for child_node in children(module_node)
        if is_export(child_node)
            for exported in children(child_node)
                push!(exported_names, string(exported))
            end
        end
    end
    return exported_names
end

end # module UnderscorePrefixForPrivateFunctions
