module AvoidExtraneousWhitespaceBetweenOpenAndCloseCharacters

using ...Properties: is_toplevel
using ...SyntaxNodeHelpers

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
    block
    call
    parameters
    "

function _get_relevant_node(n)
    if kind(n) == K"=" && kind(n.parent) == K"parameters"
        # Find spaces around '=' used for keyword arguments
        return n.parent
    elseif kind(n) == K"row"
        return n.parent
    else
        return n
    end
end

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_toplevel, root -> begin
        for i in eachindex(ctxt.greenleaves)
            cur = ctxt.greenleaves[i]
            if i == firstindex(ctxt.greenleaves) || i == lastindex(ctxt.greenleaves)
                # Skip first and last tokens to prevent out of bounds
                continue
            end
            ctext = sourcetext(cur)

            if kind(cur) != K"Whitespace"
                # Only produce violations for whitespace nodes (ignore whitespace with newlines)
                continue
            end

            pos = cur.range.start
            node = find_syntaxnode_at_position(ctxt, pos)
            if isnothing(node)
                continue
            end

            if kind(_get_relevant_node(node)) ∉ NODE_TYPES_TO_CHECK
                continue
            end

            expected_spaces = nothing
            if sourcetext(ctxt.greenleaves[i-1]) ∈ ("[", "(", "{", "=")
                expected_spaces = 0 # No space after open delimiter
            elseif sourcetext(ctxt.greenleaves[i+1]) ∈ ("]", ")", "}", "=", ";", ",")
                expected_spaces = 0 # No space before close delimiter
            else
                expected_spaces = 1 # Exactly one space between elements
            end

            if !isnothing(expected_spaces) && length(cur.range) != expected_spaces
                msg = "Expected $expected_spaces " * (expected_spaces == 1 ? "space" : "spaces")
                report_violation(ctxt, this, source_location(root.source, pos), cur.range, msg)
            end
        end

    end)
end

end # module AvoidExtraneousWhitespaceBetweenOpenAndCloseCharacters
