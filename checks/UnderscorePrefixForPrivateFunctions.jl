module UnderscorePrefixForPrivateFunctions

include("_common.jl")

using ...Properties: get_func_name, is_export, is_function, is_module, is_toplevel

struct Check<:Analysis.Check end
id(::Check) = "underscore-prefix-for-private-functions"
severity(::Check) = 8
synopsis(::Check) = "Private functions are prefixed with one underscore _ character."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_toplevel, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, toplevel_node::SyntaxNode)
    all_exported_names = _get_exported_function_names(toplevel_node)
    for function_node in _get_function_nodes(toplevel_node)
        function_name_node = get_func_name(function_node)
        if !isnothing(function_name_node)
            function_name = string(function_name_node)
            has_underscore = startswith(function_name, "_")
            if has_underscore && function_name ∈ all_exported_names
                report_violation(ctxt, this, function_node,
                    "Function $(function_name) is exported while having a name starting with an underscore.")
            end
            if !has_underscore && function_name ∉ all_exported_names
                report_violation(ctxt, this, function_node,
                    "Function $(function_name) is not exported while having a name starting without an underscore.")
            end
        end
    end
end

function _get_function_nodes(node::SyntaxNode)::Vector{SyntaxNode}
    function_nodes = Vector{SyntaxNode}()
    for child_node in children(node)
        if is_function(child_node)
            push!(function_nodes, child_node)
        elseif is_module(child_node)
            # Recurse in the case of a module; search should be done both inside and outside modules
            # (there might be multiple Julia modules within a source file)
            append!(function_nodes, _get_function_nodes(child_node))
        end
    end
    return function_nodes
end

function _get_exported_function_names(toplevel_node::SyntaxNode)::Set{String}
    exported_names = Set{String}()
    for child_node in children(toplevel_node)
        if is_export(child_node)
            for exported in children(child_node)
                push!(exported_names, string(exported))
            end
        end
    end
    return exported_names
end

end # module UnderscorePrefixForPrivateFunctions
