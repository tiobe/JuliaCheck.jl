module ExclamationMarkInFunctionIdentifierIfMutating

using JuliaSyntax: SyntaxNode, children, is_dotted
using ...Properties: get_func_name, get_string_fn_args, is_array_indx, is_assignment, 
is_broadcasting_assignment, is_field_assignment, is_field, is_first_child, is_function,
is_mutating_call

include("_common.jl")
struct Check <: Analysis.Check end

id(::Check) = "exclamation-mark-in-function-identifier-if-mutating"
severity(::Check) = 4
synopsis(::Check) = "Only functions postfixed with an exclamation mark can mutate an argument."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, _is_nonmutating_fn, n -> check_function(this, ctxt, n))
end

function _is_array_assignment(node::SyntaxNode)::Bool
    return is_array_indx(node) && is_assignment(node.parent) && is_first_child(node)
end

_is_nonmutating_fn(n::SyntaxNode)::Bool = is_function(n) && !endswith(string(get_func_name(n)), "!")

function check_function(this::Check, ctxt::AnalysisContext, function_node::SyntaxNode)
    func_arg_strings = get_string_fn_args(function_node)
    all_mutated_variables = []
    visitor_func = function(n::SyntaxNode)
        if _is_array_assignment(n)
            mutated_var = string(first(children(n)))
            push!(all_mutated_variables, mutated_var)
        elseif is_mutating_call(n)
            mutated_var = string(children(n)[2])
            push!(all_mutated_variables, mutated_var)
        elseif is_broadcasting_assignment(n)
            mutated_var = string(first(children(n)))
            push!(all_mutated_variables, mutated_var)
        elseif is_field_assignment(n)
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

end # end ExclamationMarkInFunctionIdentifierIfMutating
