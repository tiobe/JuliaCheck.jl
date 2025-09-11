module FunctionsMutateOnlyZeroOrOneArguments

using JuliaSyntax: SyntaxNode, children, is_dotted
using ...Properties: get_string_fn_args, is_array_indx, is_assignment, 
is_broadcasting_assignment, is_field_assignment, is_field, is_first_child, is_function,
is_mutating_call

include("_common.jl")
struct Check <: Analysis.Check end

id(::Check) = "functions-mutate-only-zero-or-one-arguments"
severity(::Check) = 3
synopsis(::Check) = "Functions should change only one or zero argument(s)."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_function, n -> check_function(this, ctxt, n))
end

function _is_array_assignment(node::SyntaxNode)::Bool
    return is_array_indx(node) && is_assignment(node.parent) && is_first_child(node)
end

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
    for func_arg in func_arg_strings[2:end]
        if func_arg ∈ all_mutated_variables
            report_violation(ctxt, this, function_node,
                "Function mutates variable $(string(func_arg)) while it is not the first argument.")
        end
    end
end

end # end FunctionsMutateOnlyZeroOrOneArguments
