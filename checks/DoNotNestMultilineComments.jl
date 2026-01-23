module DoNotNestMultilineComments

using ...Properties: is_toplevel
using ...SyntaxNodeHelpers

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "do-not-nest-multiline-comments"
Analysis.severity(::Check) = 9
Analysis.synopsis(::Check) = "Don't nest multiline comments"

const ML_COMMENT = "#="

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_toplevel, node -> begin
        code = node.source.code
        comments = filter(gl -> kind(gl) == K"Comment", ctxt.greenleaves)
        for comment in comments
            text = sourcetext(comment)
            if startswith(text, ML_COMMENT) # We are only interested in multiline comments
                # Search for next comment inside comment
                found::Union{UnitRange{Int}, Nothing} = findnext(ML_COMMENT, text, length(ML_COMMENT))
                if !isnothing(found)
                    found = (comment.range.start-1) .+ found
                    report_violation(ctxt, this,
                        source_location(node.source, found.start),
                        found,
                        synopsis(this)
                        )
                end
            end
        end
        return nothing
    end)
    return nothing
end

end # module DoNotNestMultilineComments
