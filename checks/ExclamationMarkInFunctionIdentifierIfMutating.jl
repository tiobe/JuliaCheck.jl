module ExclamationMarkInFunctionIdentifierIfMutating

using JuliaSyntax: SyntaxNode, children, is_dotted
using ...MutatingFunctionsHelpers: get_mutated_variables_in_scope
using ...Properties: get_func_body, get_func_name, get_string_fn_args, is_function

include("_common.jl")
struct Check<:Analysis.Check end

Analysis.id(::Check) = "exclamation-mark-in-function-identifier-if-mutating"
Analysis.severity(::Check) = 4
Analysis.synopsis(::Check) = "Only functions postfixed with an exclamation mark can mutate an argument."

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, _is_nonmutating_fn, n -> _check_function(this, ctxt, n))
    return nothing
end

_is_nonmutating_fn(n::SyntaxNode)::Bool = is_function(n) && !endswith(string(get_func_name(n)), "!")

function _check_function(this::Check, ctxt::AnalysisContext, function_node::SyntaxNode)::Nothing
    func_arg_strings = get_string_fn_args(function_node)
    all_mutated_variables = get_mutated_variables_in_scope(ctxt, get_func_body(function_node))
    for func_arg in func_arg_strings
        if func_arg ∈ all_mutated_variables
            report_violation(ctxt, this, function_node,
                "Function mutates argument $(string(func_arg)) without having an exclamation mark.")
        end
    end
    return nothing
end

end # end ExclamationMarkInFunctionIdentifierIfMutating
