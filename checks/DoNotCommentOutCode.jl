module DoNotCommentOutCode

using ...CommentHelpers: Comment, CommentBlock, get_comment_blocks, get_range, get_text, contains_comments
using ...WhitespaceHelpers: combine_ranges
using JuliaSyntax: kind, @K_str, source_location, JuliaSyntax as JS

include("_common.jl")

"""
Some keywords and other signifiers that need to be in the string in order for it to be considered code

Based on [keywords from JuliaSyntax.jl](https://github.com/JuliaLang/JuliaSyntax.jl/blob/99e975a726a82994de3f8e961e6fa8d39aed0d37/src/julia/kinds.jl#L209)
"""
const KEYWORDS = ["baremodule", "begin", "break", "const", "continue", "do", "export",
        "for", "function", "global", "if", "import", "let", "local", "macro", "module",
        "quote", "return", "struct", "try", "using", "while", "catch", "finally", "else",
        "elseif", "end", "abstract", "as", "doc", "mutable", "outer", "primitive", "public",
        "type", "var", "(", ")"]

struct Check<:Analysis.Check end
id(::Check) = "do-not-comment-out-code"
severity(::Check) = 9
synopsis(::Check) = "Do not comment out code."


function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, contains_comments, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    comment_blocks::Vector{CommentBlock} = get_comment_blocks(node)
    for block in comment_blocks
        if _contains_code(block) # Check if entire block is code
            _report(ctxt, this, get_range(block))
        else # Check if individual lines in block are comment
            for comment in block
                if _contains_code(comment)
                    _report(ctxt, this, get_range(comment))
                end
            end
        end
    end
    return nothing
end

function _report(ctxt::AnalysisContext, this::Check, range::UnitRange)
    report_violation(ctxt, this, range, "Comment contains code")
end

# If JS can parse the comment contents, it must be code
function _contains_code(text::AbstractString)::Bool
    if !any(occursin(text), KEYWORDS) return false end
    try
        JS.parseall(SyntaxNode, text)
    catch
        return false
    end
    return true
end

function _contains_code(comment::Union{Comment, CommentBlock})::Bool
    return _contains_code(get_text(comment))
end

end # module DoNotCommentOutCode
