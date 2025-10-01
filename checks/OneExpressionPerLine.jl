module OneExpressionPerLine

using JuliaSyntax: has_flags, is_leaf, source_location, sourcetext, JuliaSyntax as JS
using ...Properties: is_toplevel
using ...SyntaxNodeHelpers: ancestors
using ...WhitespaceHelpers: get_line_range

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "one-expression-per-line"
severity(::Check) = 7
synopsis(::Check) = "The number of expressions per line is limited to one."

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, _has_semicolon_statements, n -> _check(this, ctxt, n))
    return nothing
end

"""
Any statement with a semicolon in its trivia deserves further consideration.

Excludes vcat and parameter usage of ;. See also the Julia documentation:
https://docs.julialang.org/en/v1/base/punctuation/

> semicolons separate statements, begin a list of keyword arguments in
> function declarations or calls, or are used to separate array literals
> for vertical concatenation
"""
function _has_semicolon_statements(node::SyntaxNode)::Bool
    return !is_leaf(node) &&
      _has_semicolon_child(node) &&
      !_is_excluded_context(node) &&
      !_has_parent_with_semicolon_child(node)
end

function _has_semicolon_child(node::SyntaxNode)::Bool
    return any(n -> kind(n) == K";", children(node.raw))
end

function _is_excluded_context(node::SyntaxNode)::Bool
    return any(n -> kind(n) ∈ KSet"parameters typed_vcat vcat", ancestors(node; include_self = true))
end

function _has_parent_with_semicolon_child(node::SyntaxNode)::Bool
    for ancestor in ancestors(node)
        if _has_semicolon_child(ancestor)
            return true
        end
    end
    return false
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    nodes_to_report = _get_nodes_to_report(node)
    if length(nodes_to_report) > 0
        for new_node in nodes_to_report
            node_info = source_location(new_node.source, new_node.position)
            node_line = first(node_info)
            range = get_line_range(node_line, new_node.source)
            report_violation(ctxt, this, (node_line, 0), range, "Do not concatenate statements with a semicolon.")
        end
    end
    return nothing
end

function _get_nodes_to_report(node::SyntaxNode)
    nodes_to_report = []
    green_children = children(node.raw)
    split_arrays = _split_by_newline(green_children)
    for split_array in split_arrays
        for i in eachindex(split_array)
            gc = split_array[i]
            if kind(gc) == K";" && i != lastindex(split_array)
                push!(nodes_to_report, node)
            end
        end
    end
    return nodes_to_report
end

function _split_by_newline(gc_list)
    separated_list = []
    current_list = []
    for gc in gc_list
        if kind(gc) == K"NewlineWs"
            push!(separated_list, current_list)
            current_list = []
        else
            push!(current_list, gc)
        end
    end
    push!(separated_list, current_list)
    return separated_list
end

end # module OneExpressionPerLine
