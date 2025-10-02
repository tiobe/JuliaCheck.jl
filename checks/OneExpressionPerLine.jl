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

We also stick intentionally to analyzing the highest level statement that can be found.
Analyzing deeper within concatenated statements may lead to duplicate reporting
or storing of global data (both of which is not wanted).
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
    lines_to_report = Set{Integer}()
    nodes_to_check = _get_subnodes_to_check(node)
    for subnode in nodes_to_check
        lines_to_report = union!(lines_to_report, _get_semicolon_concat_from_node(subnode))
    end
    for violation_line in sort(collect(lines_to_report))
        range = get_line_range(violation_line, node.source)
        report_violation(ctxt, this, (violation_line, 0), range, "Do not concatenate statements with a semicolon.")
    end
    return nothing
end

function _get_subnodes_to_check(node::SyntaxNode)::Set{SyntaxNode}
    nodes_to_check = Set{SyntaxNode}()
    if !is_leaf(node)
        for child_node in children(node)
            union!(nodes_to_check, _get_subnodes_to_check(child_node))
        end
        if _has_semicolon_child(node)
            push!(nodes_to_check, node)
        end
    end
    return nodes_to_check
end

function _get_semicolon_concat_from_node(node::SyntaxNode)::Set{Integer}
    node_info = source_location(node.source, node.position)
    lines_to_report = Set{Integer}()
    offset = 0
    green_children = children(node.raw)
    for green_idx in eachindex(green_children)
        current_gc = green_children[green_idx]
        next_i = nextind(green_children, green_idx)
        next_gc = checkbounds(Bool, green_children, next_i) ? green_children[next_i] : nothing
        if kind(current_gc) == K";"
            if !isnothing(next_gc) && kind(next_gc) != K"NewlineWs" 
                push!(lines_to_report, first(node_info) + offset)
            end
        end
        if kind(current_gc) == K"NewlineWs"
            offset = offset + 1
        end
    end
    return lines_to_report
end

end # module OneExpressionPerLine
