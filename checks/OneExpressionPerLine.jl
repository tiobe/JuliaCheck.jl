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
    return !is_leaf(node) && _has_semicolon_child(node) && !_is_excluded_context(node)
end

function _has_semicolon_child(node::SyntaxNode)::Bool
    return any(n -> kind(n) == K";", children(node.raw))
end

function _is_excluded_context(node::SyntaxNode)::Bool
    return any(n -> kind(n) ∈ KSet"parameters typed_vcat vcat", ancestors(node; include_self = true))
end

"""
Checks whether a given node contains multiple statements.

The one case that this rule is meant to exclude is code that's written like this:
x = 6;
x + 2;

While not really nice Julia, it's valid Julia, and might be a common mistake if the
writer of the code is used to a C-style language and habitually postfixes every
statement with a semicolon.
"""
function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    if length(children(node)) > 1 || !_has_semicolon_at_end(node)
        node_info = source_location(node.source, node.position)
        node_line = first(node_info)
        range = get_line_range(node_line, node.source)
        report_violation(ctxt, this, (node_line, 0), range, "Do not concatenate statements with a semicolon.")
    end
    return nothing
end

const ENDINGS = [";\r", ";\n"]

function _has_semicolon_at_end(node::SyntaxNode)::Bool
    src = string(sourcetext(node))
    if any(occursin(src), ENDINGS) || endswith(src, ';')
        return true
    end
    return false
end

end # module OneExpressionPerLine
