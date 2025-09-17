module IndentationLevelsAreFourSpaces

include("_common.jl")

using ...Properties: is_toplevel
using ...SyntaxNodeHelpers

struct Check<:Analysis.Check end
id(::Check) = "indentation-levels-are-four-spaces"
severity(::Check) = 7
synopsis(::Check) = "Indentation should be a multiple of four spaces"

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_toplevel, n -> begin
        for gl in ctxt.greenleaves
            # We will inspect nodes of kind [NewlineWs] containing indentation spaces
            # and possibly (most of the time, in fact) starting with a line break, but
            # not ending with one.
            if kind(gl) != K"NewlineWs"
                continue
            end
            text = sourcetext(gl)
            indenttext = replace(text, r" *\r?\n(.*)" => s"\1")

            # Tabs are flagged by another rule. To prevent double report, account for
            # their presence here, counting 4-1 extra spaces for each tab.
            indentation::Int = length(indenttext) + 3 * count(r"\t", indenttext)
            if rem(indentation, 4) > 0
                rng = range(gl.range.stop - length(indenttext) + 1, length=length(indenttext))
                pos = source_location(n.source, rng.start)
                report_violation(ctxt, this, pos, rng, synopsis(this))
            end
        end
    end)

    return nothing
end

end # module IndentationLevelsAreFourSpaces
