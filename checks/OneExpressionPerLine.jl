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
    green_children = children(node.raw)
    already_reported = false
    offset = 0
    for green_idx in eachindex(green_children)
        current_gc = green_children[green_idx]
        next_i = nextind(green_children, green_idx)
        next_gc = checkbounds(Bool, green_children, next_i) ? green_children[next_i] : nothing
        if kind(current_gc) == K";" && !already_reported
            if !isnothing(next_gc) && kind(next_gc) == K"NewlineWs" 
                _report_node(this, ctxt, node, offset)
                already_reported = true
            end
        end
        if kind(current_gc) == K"NewlineWs"
            offset = offset + 1
            already_reported = false
            continue
        end
    end
    return nothing
end

function _report_node(this::Check, ctxt::AnalysisContext, node::SyntaxNode, offset::Integer)::Nothing
    node_info = source_location(node.source, node.position)
    node_line = first(node_info) + offset
    range = get_line_range(node_line, node.source)
    report_violation(ctxt, this, (node_line, 0), range, "Do not concatenate statements with a semicolon.")
    return nothing
end

end # module OneExpressionPerLine
