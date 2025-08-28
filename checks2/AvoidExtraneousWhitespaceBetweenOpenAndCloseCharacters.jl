module AvoidExtraneousWhitespaceBetweenOpenAndCloseCharacters

using ...Properties: is_toplevel
using ...SyntaxNodeHelpers

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "avoid-extraneous-whitespace-between-open-and-close-characters"
severity(::Check) = 7
synopsis(::Check) = "Avoid extraneous whitespace inside parentheses, square brackets or braces."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_toplevel, root -> begin
        prev::Union{GreenLeaf, Nothing} = nothing

        for gl in ctxt.greenleaves
            text = sourcetext(gl)
            if (!isnothing(prev)
                && kind(gl) == K"Whitespace"
                && all(c -> c == ' ', text) # Only report if node consists fully out of spaces
                )

                pos = gl.range.start
                prevtext = sourcetext(prev)

                expected_spaces = nothing
                if prevtext ∈ ("[", "]", "(", ")", "{", "}")
                    expected_spaces = 0
                elseif prevtext == "="
                    node = find_syntaxnode_at_position(ctxt, pos)
                    if kind(node.parent) ∈ KSet"parameters"
                        expected_spaces = 0
                    end
                else
                    expected_spaces = 1
                end

                if !isnothing(expected_spaces) && length(gl.range) != expected_spaces
                    msg = "Expected $expected_spaces " * (expected_spaces == 1 ? "space" : "spaces")
                    report_violation(ctxt, this, source_location(root.source, pos), gl.range, msg)
                end
            end

            prev = gl
        end

    end)
end

end # module AvoidExtraneousWhitespaceBetweenOpenAndCloseCharacters
