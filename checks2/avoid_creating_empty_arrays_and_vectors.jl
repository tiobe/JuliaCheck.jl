module AvoidCreatingEmptyArraysAndVectors

using JuliaSyntax: SyntaxNode, @K_str, children, kind
using ..SymbolTable: id_is_declaration
using ...Properties: is_array_indx, is_assignment, is_call, is_vect

include("_common.jl")
struct Check <: Analysis.Check end

id(::Check) = "avoid-creating-empty-arrays-and-vectors"
severity(::Check) = 8
synopsis(::Check) = "Avoid resizing arrays after initialization."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_assignment, n -> check(this, ctxt, n))
end

function check(this::Check, ctxt::AnalysisContext, assignment_node::SyntaxNode)
    assignment_variable_node = first(children(assignment_node))
    assignment_value_node = last(children(assignment_node))
    if ! id_is_declaration(ctxt.symboltable, assignment_variable_node)
        return
    end
    if _has_sizehint(assignment_node)
        return
    end
    _check_for_naive_empty_initialization(this, ctxt, assignment_node, assignment_value_node)
    _check_for_usage_of_empty_keyword(this, ctxt, assignment_node, assignment_value_node)
    _check_for_empty_array_initialization(this, ctxt, assignment_node, assignment_value_node)
end

function _has_sizehint(assignment_node::SyntaxNode)::Bool
    assigned_variable = first(children(assignment_node)).data.val
    sibling_nodes = assignment_node.parent.children
    for sibling_node in sibling_nodes
        if is_call(sibling_node) && _get_function_name_from_call_node(sibling_node) == "sizehint!"
            var_node = sibling_node.children[2]
            if var_node.data.val == assigned_variable
                return true
            end
        end
    end
    return false
end

function _get_function_name_from_call_node(call_node::SyntaxNode)::String
    call_type_node = first(children(call_node))
    function_name = String(call_type_node.data.val)
    return function_name
end

function _check_for_naive_empty_initialization(this::Check, ctxt::AnalysisContext, basenode::SyntaxNode, rhs::SyntaxNode)
    if is_vect(rhs)
        if isnothing(rhs.data.val) && first(rhs.children.size) == 0
            report_violation(ctxt, this, basenode, "Avoid resizing arrays after initialization.")
        end
    end
end

function _check_for_usage_of_empty_keyword(this::Check, ctxt::AnalysisContext, basenode::SyntaxNode, rhs::SyntaxNode)
    if is_call(rhs)
        keyword = first(children(rhs))
        if string(keyword) == "empty"
            report_violation(ctxt, this, basenode, "Avoid resizing arrays after initialization.")
        end
    end
end

function _check_for_empty_array_initialization(this::Check, ctxt::AnalysisContext, basenode::SyntaxNode, rhs::SyntaxNode)
    if is_array_indx(rhs)
        if isnothing(rhs.data.val)
            report_violation(ctxt, this, basenode, "Avoid resizing arrays after initialization.")
        end
    end
end

end # end AvoidCreatingEmptyArraysAndVectors
