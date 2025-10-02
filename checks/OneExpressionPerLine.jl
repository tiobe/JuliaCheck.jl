module OneExpressionPerLine

using JuliaSyntax: GreenNode, has_flags, is_leaf, source_location, sourcetext, JuliaSyntax as JS
using ...Properties: is_toplevel
using ...SyntaxNodeHelpers: ancestors
using ...WhitespaceHelpers: get_line_range

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "one-expression-per-line"
severity(::Check) = 7
synopsis(::Check) = "The number of expressions per line is limited to one."

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_toplevel, n -> _check(this, ctxt, n))
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
function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    # Avoids multiple checks on toplevels.
    if any(n -> is_toplevel(n), ancestors(node; include_self = false))
        return nothing
    end
    lines_to_report = Set{Integer}()
    nodes_to_check = _get_subnodes_to_check(node)
    for subnode in nodes_to_check
        lines_to_report = union!(lines_to_report, _find_semicolon_lines(subnode))
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
        if _has_semicolon_child(node)
            push!(nodes_to_check, node)
        else
            for child_node in children(node)
                if !_is_allowed_context(child_node)
                    union!(nodes_to_check, _get_subnodes_to_check(child_node))
                end
            end
        end
    end
    return nodes_to_check
end

function _is_allowed_context(node::SyntaxNode)::Bool
    return kind(node) ∈ KSet"parameters typed_vcat vcat"
end

function _has_semicolon_child(node::SyntaxNode)::Bool
    green = children(node.raw)
    return any(idx -> _has_semicolon_without_newline(green, idx), eachindex(green))
end

function _has_semicolon_without_newline(green_children, green_idx::Integer)::Bool
    current_gc = green_children[green_idx]
    next_i = nextind(green_children, green_idx)
    next_gc = checkbounds(Bool, green_children, next_i) ? green_children[next_i] : nothing
    if kind(current_gc) == K";"
        if !isnothing(next_gc) && kind(next_gc) != K"NewlineWs" 
            return true
        end
    end
    return false
end

function _find_semicolon_lines(node::SyntaxNode)::Set{Integer}
    node_info = source_location(node.source, node.position)
    lines_to_report = Set{Integer}()
    offset = 0
    green_children = children(node.raw)
    for green_idx in eachindex(green_children)
        if (_has_semicolon_without_newline(green_children, green_idx))
            push!(lines_to_report, first(node_info) + offset)
        end
        if kind(green_children[green_idx]) == K"NewlineWs"
            offset = offset + 1
        end
    end
    return lines_to_report
end

end # module OneExpressionPerLine
