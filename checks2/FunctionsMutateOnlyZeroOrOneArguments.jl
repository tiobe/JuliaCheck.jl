module FunctionsMutateOnlyZeroOrOneArguments

using JuliaSyntax: SyntaxNode, children, is_dotted
using ...MutatingFunctionsHelpers: get_mutated_variables_in_fn
using ...Properties: get_string_fn_args, is_function

include("_common.jl")
struct Check <: Analysis.Check end

id(::Check) = "functions-mutate-only-zero-or-one-arguments"
severity(::Check) = 3
synopsis(::Check) = "Functions should change only one or zero argument(s)."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_function, n -> check_function(this, ctxt, n))
end

function check_function(this::Check, ctxt::AnalysisContext, function_node::SyntaxNode)
    func_arg_strings = get_string_fn_args(function_node)
    all_mutated_variables = get_mutated_variables_in_fn(ctxt, function_node)
    for func_arg in func_arg_strings[2:end]
        if func_arg ∈ all_mutated_variables
            report_violation(ctxt, this, function_node,
                "Function mutates variable $(string(func_arg)) while it is not the first argument.")
        end
    end
end

end # end FunctionsMutateOnlyZeroOrOneArguments
