module MultilineCommentsForManyLines

using ...CommentHelpers: CommentBlock, get_comment_blocks, get_range, contains_comments

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "multiline-comments-for-many-lines"
Analysis.severity(::Check) = 9
Analysis.synopsis(::Check) = "Use multiline comments for large blocks."

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, contains_comments, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    comment_blocks::Vector{CommentBlock} = get_comment_blocks(node)
    for block in comment_blocks
        if _too_large(block)
            report_violation(ctxt, this, get_range(block), "Replace many comments with a single block comment.")
        end
    end
    return nothing
end

"More than 5 consecutive inline comments justify replacing with a block comment"
function _too_large(block::CommentBlock)::Bool
    return length(block) >= 5
end

end # module MultilineCommentsForManyLines
