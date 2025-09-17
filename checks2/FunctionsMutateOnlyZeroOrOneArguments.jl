module FunctionsMutateOnlyZeroOrOneArguments

using JuliaSyntax: SyntaxNode, children, is_dotted
using ...MutatingFunctionsHelpers: get_mutated_variables_in_scope
using ...Properties: get_flattened_fn_arg_nodes, get_string_arg, is_function

include("_common.jl")
struct Check <: Analysis.Check end

id(::Check) = "functions-mutate-only-zero-or-one-arguments"
severity(::Check) = 3
synopsis(::Check) = "Functions should change only one or zero argument(s)."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_function, n -> check_function(this, ctxt, n))
end

function check_function(this::Check, ctxt::AnalysisContext, function_node::SyntaxNode)
    func_arg_nodes = get_flattened_fn_arg_nodes(function_node)
    all_mutated_variables = get_mutated_variables_in_scope(ctxt, function_node)
    for func_arg in func_arg_nodes[2:end]
        func_arg_string = get_string_arg(func_arg)
        if func_arg_string ∈ all_mutated_variables
            report_violation(ctxt, this, func_arg,
                "Function mutates variable $(string(func_arg_string)) while it is not the first argument.")
        end
    end
end

end # end FunctionsMutateOnlyZeroOrOneArguments
