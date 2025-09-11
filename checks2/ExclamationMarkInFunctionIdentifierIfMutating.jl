module ExclamationMarkInFunctionIdentifierIfMutating

using JuliaSyntax: SyntaxNode, @K_str, children, is_dotted, is_leaf, kind
using ...Properties: get_func_arguments, get_func_name, is_array_indx, is_assignment, is_call, is_field, is_first_child, is_function

include("_common.jl")
struct Check <: Analysis.Check end

id(::Check) = "exclamation-mark-in-function-identifier-if-mutating"
severity(::Check) = 4
synopsis(::Check) = "Only functions postfixed with an exclamation mark can mutate an argument."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, _is_nonmutating_fn, n -> check_function(this, ctxt, n))
end

"""
Naïve implementation. Does not recurse. Assumption is that we can trust
whether a function has been marked as mutating (so has the ! convention
that this rule tests for). Furthermore, the second child should be an
identifier - otherwise we might be checking against the actual function
definition itself rather than its invocation.
"""
function _is_mutating_call(node::SyntaxNode)::Bool
    return is_call(node) && _call_name_has_exclamation(node) && kind(children(node)[2]) == K"Identifier"
end

function _call_name_has_exclamation(call_node::SyntaxNode)::Bool
    call_type_node = first(children(call_node))

    # anonymous functions never have an exclamation point in front of them
    if isnothing(string(call_type_node))
        return false
    end
    call_name = string(call_type_node)
    return endswith(call_name, "!")
end

function _is_array_assignment(node::SyntaxNode)::Bool
    return is_array_indx(node) && is_assignment(node.parent) && is_first_child(node)
end

_is_nonmutating_fn(n::SyntaxNode)::Bool = is_function(n) && !endswith(string(get_func_name(n)), "!")
_is_dotted_assignment(n::SyntaxNode)::Bool = is_assignment(n) && is_dotted(n)
_is_field_assignment(n::SyntaxNode)::Bool = is_assignment(n) && is_field(first(children(n)))

function check_function(this::Check, ctxt::AnalysisContext, function_node::SyntaxNode)
    func_arg_strings = _get_string_fn_args(function_node)
    all_mutated_variables = []
    visitor_func = function(n::SyntaxNode)
        if _is_array_assignment(n)
            mutated_var = string(first(children(n)))
            push!(all_mutated_variables, mutated_var)
        elseif _is_mutating_call(n)
            mutated_var = string(children(n)[2])
            push!(all_mutated_variables, mutated_var)
        elseif _is_dotted_assignment(n)
            mutated_var = string(first(children(n)))
            push!(all_mutated_variables, mutated_var)
        elseif _is_field_assignment(n)
            field_assignment = first(children(n))
            mutated_var = string(first(children(field_assignment)))
            push!(all_mutated_variables, mutated_var)
        end
    end
    Analysis.dfs_traversal(ctxt, function_node, visitor_func)
    for func_arg in func_arg_strings
        if func_arg ∈ all_mutated_variables
            report_violation(ctxt, this, function_node,
                "Function mutates argument $(string(func_arg)) without having an exclamation mark.")
        end
    end
end

function _get_string_fn_args(function_node::SyntaxNode)::Vector{String}
    func_arguments = get_func_arguments(function_node)
    func_arg_str = []
    for arg in func_arguments
        push!(func_arg_str, _get_string_arg(arg))
    end
    return func_arg_str
end

function _get_string_arg(arg_node::SyntaxNode)::String
    if !is_leaf(arg_node)
        return string(first(children(arg_node)))
    else
        return string(arg_node)
    end
end

end # end ExclamationMarkInFunctionIdentifierIfMutating
