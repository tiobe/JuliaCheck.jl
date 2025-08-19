module AvoidCreatingEmptyArraysAndVectors

using JuliaSyntax: SyntaxNode, @K_str, children, kind
using ...Checks: is_enabled
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
    rhs = last(children(assignment_node))
    _check_for_naive_empty_initialization(this, ctxt, assignment_node, rhs)
    _check_for_usage_of_empty_keyword(this, ctxt, assignment_node, rhs)
    _check_for_empty_array_initialization(this, ctxt, assignment_node, rhs)
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
        keyword = children(rhs)[1]
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
