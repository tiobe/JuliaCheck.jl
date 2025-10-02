module CommentHelpers

using JuliaSyntax: @K_str, @KSet_str, SyntaxNode, kind, child_position_span, view, JuliaSyntax as JS
using ..WhitespaceHelpers: combine_ranges, normalized_green_child_range

export Comment, CommentBlock, get_comment_blocks, get_range, get_text, contains_comments

struct Comment
    range::UnitRange
    text::AbstractString
end

"Block of consecutive line comments, with only whitespace in between"
const CommentBlock = Vector{Comment}

"""
Returns true if the node has any direct children that are comments. This does *not* include
docstrings, only inline comments `# Comment` and multiline comments `#= Comment =#`
"""
function contains_comments(sn::SyntaxNode)::Bool
    gn = sn.raw
    return !isnothing(gn.children) && any(n -> kind(n) == K"Comment", gn.children)
end

function get_comments(sn::SyntaxNode)::Vector{Comment}
    comments = []
    for (i, ch) in enumerate(sn.raw.children)
        if kind(ch) == K"Comment"
            range = normalized_green_child_range(sn, i)
            push!(comments, Comment(range, JS.view(sn.source, range)))
        end
    end
    return comments
end

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
            range = normalized_green_child_range(sn, i)
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

"Get the byte range spanning the entire comment or block"
get_range(comment::Comment)::UnitRange = comment.range
get_range(block::CommentBlock)::UnitRange = combine_ranges(map(get_range, block))

end # module CommentHelpers
