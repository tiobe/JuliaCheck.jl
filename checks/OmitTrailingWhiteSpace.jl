module OmitTrailingWhiteSpace

using ...Properties: is_toplevel

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "omit-trailing-white-space"
Analysis.severity(::Check) = 7
Analysis.synopsis(::Check) = "Omit spaces at the end of a line"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_toplevel, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    code = node.source.code
    for m in eachmatch(r"( +)\r?\n", code)
        line::Int = count("\n", code[1:m.offset]) + 1
        col::Int = m.offset - something(findprev('\n', code, m.offset), 1) + 1
        bufferrange = m.offset:m.offset + length(m.captures[1])
        report_violation(ctxt, this, (line, col), bufferrange, synopsis(this))
    end
    return nothing
end

end # module OmitTrailingWhiteSpace

