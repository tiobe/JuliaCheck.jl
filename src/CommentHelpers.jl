module CommentHelpers

using JuliaSyntax: @K_str, @KSet_str, SyntaxNode, kind, child_position_span, view, JuliaSyntax as JS
using ..WhitespaceHelpers: normalized_child_position_span

export get_comment_blocks, get_text

struct Comment
    range::UnitRange
    text::AbstractString
end

const CommentBlock = Vector{Comment}

"""
Get the range and text representation of the direct children that are comment nodes.
Subsequent single-line comments are merged. Only sibling comments can ever belong to the same block.
"""
function get_comment_blocks(sn::SyntaxNode)::Vector{CommentBlock}
    res = []
    g_chs = sn.raw.children
    curblock = []
    for (i, ch) in enumerate(g_chs)
        if kind(ch) == K"Comment"
            range = normalized_child_position_span(sn, sn.raw, i)
            push!(curblock, Comment(range, JS.view(sn.source, range)))
        elseif kind(ch) ∈ KSet"Whitespace NewlineWs"
            continue
        else
            if !isempty(curblock)
                push!(res, curblock)
                curblock = []
            end
        end
    end
    if !isempty(curblock) push!(res, curblock) end
    return res
end

function get_text(block::CommentBlock)::String
    return join(map(c -> strip(c.text, ['#', '=']), block), "\n")
end

end # module CommentHelpers
