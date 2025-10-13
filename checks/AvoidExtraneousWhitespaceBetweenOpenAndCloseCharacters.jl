module AvoidExtraneousWhitespaceBetweenOpenAndCloseCharacters

using JuliaSyntax: SourceFile, has_flags, head, PARENS_FLAG, is_prefix_call
using ...Properties: is_toplevel

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "avoid-extraneous-whitespace-between-open-and-close-characters"
severity(::Check) = 7
synopsis(::Check) = "Avoid extraneous whitespace inside parentheses, square brackets or braces."

"""
Syntax node types for which whitespace should be checked.
See https://docs.julialang.org/en/v1/devdocs/ast/#Bracketed-forms for an overview.
"""
const NODE_TYPES_TO_CHECK = KSet"
    ref
    typed_vcat
    typed_hcat
    typed_ncat
    curly
    vect
    hcat
    vcat
    ncat
    comprehension
    typed_comprehension
    tuple
    parameters
    "

function _get_relevant_node(n::SyntaxNode)::SyntaxNode
    if kind(n) == K"=" && kind(n.parent) == K"parameters"
        # Find spaces around '=' used for keyword arguments
        return n.parent
    elseif kind(n) == K"row"
        return n.parent
    else
        return n
    end
end

function _should_check(node::SyntaxNode)::Bool
    if isnothing(node)
        return false
    end
    relnode = _get_relevant_node(node)
    if kind(relnode) == K"block" && has_flags(head(relnode), PARENS_FLAG)
        # Do not check every `block` node, because this is also used for struct default value assignments.
        # Only check `block-p` syntax: e.g.: (a; b; c)
        return true
    elseif kind(relnode) == K"call"
        if is_prefix_call(relnode)
            # Check normal prefix function calls: f(a, b)
            return true
        elseif sourcetext(relnode.children[2]) == "=>"
            # Check spaces around dictionary pair (a => 1, b => 2)
            return true
        else
            # Skip other calls
            return false
        end
    end
    return kind(relnode) in NODE_TYPES_TO_CHECK
end

function _check(this::Check, ctxt::AnalysisContext, sf::SourceFile)::Nothing
    for i in eachindex(ctxt.greenleaves)
        if i == firstindex(ctxt.greenleaves) || i == lastindex(ctxt.greenleaves)
            # Skip first and last tokens to prevent out of bounds
            continue
        end
        cur = ctxt.greenleaves[i]
        next = ctxt.greenleaves[i+1]

        if kind(cur) != K"Whitespace"
            # Only produce violations for whitespace nodes (ignore whitespace with newlines)
            continue
        elseif kind(next) == K"Comment"
            # Skip whitespace that is followed by a comment
            continue
        end

        pos = cur.range.start
        node = find_syntaxnode_at_position(ctxt, pos)
        if !_should_check(node)
            continue
        end

        expected_spaces = nothing
        if sourcetext(ctxt.greenleaves[i-1]) ∈ ("[", "(", "{", "=")
            expected_spaces = 0 # No space after open delimiter
        elseif sourcetext(next) ∈ ("]", ")", "}", "=", ";", ",")
            expected_spaces = 0 # No space before close delimiter
        else
            expected_spaces = 1 # Exactly one space between elements
        end

        if !isnothing(expected_spaces) && length(cur.range) != expected_spaces
            msg = "Expected $expected_spaces " * (expected_spaces == 1 ? "space" : "spaces")
            report_violation(ctxt, this, source_location(sf, pos), cur.range, msg)
        end
    end
    return nothing
end

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_toplevel, root -> _check(this, ctxt, root.source))
    return nothing
end

end # module AvoidExtraneousWhitespaceBetweenOpenAndCloseCharacters
