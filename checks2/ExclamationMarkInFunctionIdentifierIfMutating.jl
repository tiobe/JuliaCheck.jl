module ExclamationMarkInFunctionIdentifierIfMutating

using JuliaSyntax: SyntaxNode, @K_str, children, kind
using ..SymbolTable: node_is_declaration_of_variable
using ...Properties: get_func_arguments, get_func_name, is_array_indx, is_assignment, is_call, is_function, is_vect
using ...SyntaxNodeHelpers: ancestors

include("_common.jl")
struct Check <: Analysis.Check end

id(::Check) = "exclamation-mark-in-function-identifier-if-mutating"
severity(::Check) = 4
synopsis(::Check) = "Only functions postfixed with an exclamation mark can mutate an argument."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_assignment, n -> check_assignment(this, ctxt, n))
    register_syntaxnode_action(ctxt, is_array_indx, n -> check_array_assignment(this, ctxt, n))
    register_syntaxnode_action(ctxt, is_mutating_call, n -> check_mutating_call(this, ctxt, n))
end

function check_assignment(this::Check, ctxt::AnalysisContext, assignment_node::SyntaxNode)
    if ! node_is_declaration_of_variable(ctxt.symboltable, first(children(assignment_node)))
        return
    end
    mutated_var = get_mutated_variable(potential_mutation_node)
end

function check_array_assignment(this::Check, ctxt::AnalysisContext, array_assignment_node::SyntaxNode)
    mutated_var = get_mutated_variable(array_assignment_node)
end

function check_mutating_call(this::Check, ctxt::AnalysisContext, call_node::SyntaxNode)
    mutated_var = get_mutated_variable(children(call_node)[2])
    for ancestor_node in ancestors(call_node)
        if is_function(ancestor_node)
            func_arguments = get_func_arguments(ancestor_node)
            func_name = string(get_func_name(ancestor_node))
            for arg in func_arguments
                arg_var = string(first(children(arg)))
                if mutated_var == arg_var && ! endswith(func_name, "!")
                    report_violation(ctxt, this, ancestor_node,
                    "Function mutates variable $(string(mutated_var)) without having an exclamation mark."
                    )
                end
            end
        end
    end
end

"""
Naïve implementation. Does not recurse. Assumption is that we can trust
whether a function has been marked as mutating (so has the ! convention
that this rule tests for). Furthermore, the second child should be an
identifier - otherwise we might be checking against the actual function
definition itself rather than its invocation.

# TODO: Have some mechanism that with certainty only looks at function calls,
        and not function definitions. Currently this feels iffy.
"""
function is_mutating_call(node::SyntaxNode)::Bool
    return is_call(node) && _function_name_has_exclamation(node) && kind(children(node)[2]) == K"Identifier"
end

function _function_name_has_exclamation(call_node::SyntaxNode)::Bool
    call_type_node = first(children(call_node))
    function_name = String(call_type_node.data.val)
    return endswith(function_name, "!")
end

# TODO Only works for assignments for now. Needs to be checked as well for calls
#      and any other types we might find here.
function get_mutated_variable(node::SyntaxNode)::String
    return string(node)
end

function get_all_function_nodes_containing_args(var::String)::Vector{SyntaxNode}
    return []
end

end # end ExclamationMarkInFunctionIdentifierIfMutating
