module CommentHelpers

using JuliaSyntax: @K_str, @KSet_str, SyntaxNode, kind, child_position_span, view, JuliaSyntax as JS
using ..WhitespaceHelpers: normalized_child_position_span

export Comment, CommentBlock, get_comment_blocks, get_text

struct Comment
    range::UnitRange
    text::AbstractString
end

"Block of consecutive line comments, with only whitespace in between"
const CommentBlock = Vector{Comment}

"""
Get the range and text representation of the direct children that are comment nodes.
Subsequent single-line comments are merged. Only sibling comments can ever belong to the same block.
"""
function get_comment_blocks(sn::SyntaxNode)::Vector{CommentBlock}
    blocks = []
    green_children = sn.raw.children
    curblock = []
    # Iterate through green children, combining consecutive comment siblings into blocks
    # if there is only whitespace between them
    for (i, ch) in enumerate(green_children)
        if kind(ch) == K"Comment"
            range = normalized_child_position_span(sn, sn.raw, i)
            push!(curblock, Comment(range, JS.view(sn.source, range)))
        elseif kind(ch) ∈ KSet"Whitespace NewlineWs"
            continue # Whitespace does not interrupt comment block
        else
            if !isempty(curblock)
                push!(blocks, curblock) # Finish current block and set up for the next
                curblock = [] # Set up for new block
            end
        end
    end
    if !isempty(curblock) push!(blocks, curblock) end
    return blocks
end

"Get the text from a comment, excluding '#'s"
get_text(comment::Comment)::AbstractString = strip(comment.text, ['#', '='])
get_text(block::CommentBlock)::AbstractString = join(map(get_text, block), "\n")


end # module CommentHelpers
