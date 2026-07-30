module OneExpressionPerLine

using JuliaSyntax: source_location, SourceFile
using ...Properties: is_root_node
using ...SyntaxNodeHelpers: ancestors

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "one-expression-per-line"
Analysis.severity(::Check) = 7
Analysis.synopsis(::Check) = "The number of expressions per line is limited to one."

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_root_node, root -> _check(this, ctxt, root.source))
    return nothing
end

"""
Check that a semicolon is not used to separate statements.
"""
function _check(this::Check, ctxt::AnalysisContext, sf::SourceFile)::Nothing
    for i in eachindex(ctxt.greenleaves)
        cur = ctxt.greenleaves[i]
        if kind(cur) != K";"
            continue
        end

        pos = cur.range.start
        node = find_syntaxnode_at_position(ctxt, pos)
        if !_should_check(node)
            continue
        end

        if !_has_only_trivia_until_line_end(ctxt.greenleaves, i)
            report_violation(ctxt, this, source_location(sf, pos), cur.range, "Do not concatenate statements with a semicolon.")
        end
    end
    return nothing
end

"""
Excludes `vcat` and `parameter` usage of `;`.

See the Julia documentation:
https://docs.julialang.org/en/v1/base/punctuation/

> semicolons separate statements, begin a list of keyword arguments in
> function declarations or calls, or are used to separate array literals
> for vertical concatenation
"""
function _should_check(node::SyntaxNode)::Bool
    return !any(n -> kind(n) ∈ KSet"parameters typed_vcat vcat", ancestors(node, include_self=true))
end

"""
Return `true` if only trivia remains on the line after `idx` and `false` otherwise.

Trivia includes comments and whitespace.
"""
function _has_only_trivia_until_line_end(leaves::Vector{GreenLeaf}, idx::Integer)::Bool
    if idx >= lastindex(leaves)
        return true
    end

    for j in (idx + 1):lastindex(leaves)
        leaf = leaves[j]
        k = kind(leaf)

        if k == K"Comment"
            continue # Ignore comments after semicolon
        elseif k == K"NewlineWs"
            return true
        elseif k == K"Whitespace"
            if contains(sourcetext(leaf), '\n') || contains(sourcetext(leaf), '\r')
                return true
            end
            continue
        else
            return false
        end
    end

    return true
end

end # module OneExpressionPerLine
