module AvoidCreatingEmptyArraysAndVectors

using JuliaSyntax: SyntaxNode, @K_str, children, kind
using ..SymbolTable: node_is_declaration_of_variable
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
    if ! node_is_declaration_of_variable(ctxt.symboltable, first(children(assignment_node)))
        return
    end
    assignment_value_node = last(children(assignment_node))
    if _is_naive_empty_initialization(assignment_value_node) ||
       _is_empty_keyword(assignment_value_node) ||
       _is_empty_array_initialization(assignment_value_node)
        if _has_sizehint(assignment_node)
            return
        end
        report_violation(ctxt, this, assignment_node, "Avoid resizing arrays after initialization.")
    end
end

function _has_sizehint(assignment_node::SyntaxNode)::Bool
    assigned_variable = first(children(assignment_node)).data.val
    sibling_nodes = children(assignment_node.parent)
    for sibling_node in sibling_nodes
        if is_call(sibling_node) && _get_function_name_from_call_node(sibling_node) == "sizehint!"
            var_node = children(sibling_node)[2]
            if var_node.data.val == assigned_variable
                return true
            end
        end
    end
    return false
end

function _get_function_name_from_call_node(call_node::SyntaxNode)::String
    call_type_node = first(children(call_node))
    function_name = string(call_type_node)
    return function_name
end

function _is_naive_empty_initialization(node::SyntaxNode)::Bool
    # A empty 'vect' kind SyntaxNode has two children; a 'ref' and a 'size'.
    # Unlike what we might expect from a 'size' field in a child, this has nothing to do
    # with the number of children; instead it seems to be a property.
    return is_vect(node) && isnothing(node.data.val) && first(node.children.size) == 0
end

function _is_empty_keyword(node::SyntaxNode)::Bool
    return is_call(node) && string(first(children(node))) == "empty"
end

# Single child means that there is nothing inside the array.
function _is_empty_array_initialization(node::SyntaxNode)::Bool
    return is_array_indx(node) && numchildren(node) == 1
end

end # end AvoidCreatingEmptyArraysAndVectors
