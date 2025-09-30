module OneExpressionPerLine

using JuliaSyntax: has_flags, is_leaf, sourcetext, JuliaSyntax as JS
using ...Properties: is_assignment, is_toplevel

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "one-expression-per-line"
severity(::Check) = 7
synopsis(::Check) = "The number of expressions per line is limited to one."

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, _is_toplevel_semicolon, n -> _check(this, ctxt, n))
    return nothing
end

"""
JuliaSyntax parses semicolon-concatenated statements to a toplevel-; node.

To distinguish the semicolon-separated statement, it's necessary to check against the
specific flag, which (unfortunately) is not nicely exposed like other flags and needs
to have its own explicit check.
"""
function _is_toplevel_semicolon(node)::Bool
    return is_toplevel(node) && has_flags(node, JS.TOPLEVEL_SEMICOLONS_FLAG)
end

"""
Checks whether a given toplevel-; node contains multiple statements.

The one case that this rule is meant to exclude is code that's written like this:
x = 6;
x + 2;

While not really nice Julia, it's valid Julia, and might be a common mistake if the
writer of the code is used to a C-style language and habitually postfixes every
statement with a semicolon.
"""
function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    if is_leaf(node)
        return nothing
    end
    if length(children(node)) > 1 || !_has_single_semicolon_at_end(node)
        report_violation(ctxt, this, node, "Do not concatenate statements with a semicolon.")
    end
    return nothing
end

function _has_single_semicolon_at_end(node::SyntaxNode)::Bool
    sourcetxt = sourcetext(node)
    nr_semicolons = count(';', sourcetxt)
    if nr_semicolons > 1
        return false
    end
    if endswith(sourcetxt, ';')
        return true
    end
    return false
end

end # module OneExpressionPerLine
