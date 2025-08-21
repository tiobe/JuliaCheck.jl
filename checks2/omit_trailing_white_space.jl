module OmitTrailingWhiteSpace

include("_common.jl")

using ...Properties: is_toplevel

struct Check <: Analysis.Check end
id(::Check) = "omit-trailing-white-space"
severity(::Check) = 7
synopsis(::Check) = "Omit spaces at the end of a line"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_toplevel, n -> check(this, ctxt, n))
end

function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    for m in eachmatch(r"( +)\r?\n", ctxt.sourcecode)
        line::Int = count("\n", ctxt.sourcecode[1:m.offset]) + 1
        col::Int = m.offset - something(findprev('\n', ctxt.sourcecode, m.offset), 1) + 1
        bufferrange = m.offset:m.offset+length(m.captures[1])
        report_violation(ctxt, this, (line,col), bufferrange, synopsis(this))
    end
end

end # module OmitTrailingWhiteSpace

