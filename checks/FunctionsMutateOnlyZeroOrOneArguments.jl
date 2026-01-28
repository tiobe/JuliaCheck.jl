module FunctionsMutateOnlyZeroOrOneArguments

using JuliaSyntax: SyntaxNode, children, is_dotted
using ...MutatingFunctionsHelpers: get_mutated_variables_in_scope
using ...Properties: get_flattened_fn_arg_nodes, get_func_body, get_string_arg, is_function

include("_common.jl")
struct Check<:Analysis.Check end
Analysis.id(::Check) = "functions-mutate-only-zero-or-one-arguments"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Functions should change only one or zero argument(s)."

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_function, n -> _check_function(this, ctxt, n))
    return nothing
end

function _check_function(this::Check, ctxt::AnalysisContext, function_node::SyntaxNode)::Nothing
    func_arg_nodes = get_flattened_fn_arg_nodes(function_node)
    all_mutated_variables = get_mutated_variables_in_scope(ctxt, get_func_body(function_node))
    for func_arg in func_arg_nodes[2:end]
        func_arg_string = get_string_arg(func_arg)
        if func_arg_string ∈ all_mutated_variables
            report_violation(ctxt, this, func_arg,
                "Function mutates variable $(string(func_arg_string)) while it is not the first argument.")
        end
    end
    return nothing
end

end # end FunctionsMutateOnlyZeroOrOneArguments
