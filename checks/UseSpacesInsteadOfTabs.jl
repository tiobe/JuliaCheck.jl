module UseSpacesInsteadOfTabs

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "use-spaces-instead-of-tabs"
Analysis.severity(::Check) = 7
Analysis.synopsis(::Check) = "Use spaces instead of tabs for indentation"

const REGEX = r"(\s*)\t+.*"

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"toplevel", node -> begin
        code = node.source.code
        starts = node.source.line_starts
        successive_pairs = collect(zip(starts, Iterators.drop(starts, 1)))
        linenr::Int = 1
        for (start,stop) in successive_pairs
            line::String = code[start:prevind(code, stop)]
            m = match(REGEX, line)
            if ! isnothing(m)
                offset::Int = length(m.captures[1])
                linepos = (linenr, offset+1)
                bufferrange = range(start + offset, length=1)
                report_violation(ctxt, this, linepos, bufferrange, synopsis(this))
            end
            linenr += 1
        end
    end)
end

end # module UseSpacesInsteadOfTabs
