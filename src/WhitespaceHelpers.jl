module WhitespaceHelpers

import JuliaSyntax: SourceFile, char_range, SyntaxNode

export followed_by_comment, difference, normalize_range, combine_ranges, find_whitespace_range

"""
Find the range of whitespace starting from `start_idx` and going either forward or backward.
"""
function find_whitespace_range(
    text::AbstractString,
    start_idx::Int,
    forward::Bool
)::UnitRange{Int}
    find = forward ? nextind : prevind
    first_find = find(text, start_idx)
    i = first_find
    last_find = nothing

    while checkbounds(Bool, text, i) && isspace(text[i])
        last_find = i
        i = find(text, i)
    end

    if isnothing(first_find) || isnothing(last_find)
        return range(first_find; length=0)
    elseif forward
        return first_find:last_find
    else # backward
        return last_find:first_find
    end
    return range(; start=1, length=0) # should not happen
end

"""
Returns true if the range in source is followed by a comment (inline comment)
This is used e.g. to exclude comment indents from whitespace checks.
"""
function followed_by_comment(range::UnitRange, source::SourceFile)::Bool
    fixedrange = char_range(source, range)
    next_char =
        fixedrange.stop < lastindex(source.code) ? source.code[fixedrange.stop+1] : ' '
    return next_char == '#'
end

"""
Convert byte range to character range in given source file.
"""
function char_range(source::SourceFile, byte_range::UnitRange{Int})::UnitRange{Int}
    if length(byte_range) == 0
        return range(thisind(source, byte_range.start); length=0)
    end
    return thisind(source, byte_range.start):thisind(source, byte_range.stop)
end

"""
Calculate the result of subtracting a set of ranges from `base_range`. Example: difference(1:20, [3:6, 10:15, 20:25]) = [1:2, 7:9, 16:19].
"""
function difference(
    one::UnitRange{Int},
    others::Vector{UnitRange{Int}}
)::Vector{UnitRange{Int}}
    result = [one]
    for other in others
        new_result = Vector{UnitRange{Int}}()
        for r in result
            append!(new_result, _difference(r, other))
        end
        result = new_result
    end
    return result
end

"""
Calculate the result of subtracting a ranges from `base_range`. Example: difference(1:20, 10:15) = [1:9, 16:20].
"""
function _difference(one::UnitRange{Int}, other::UnitRange{Int})::Vector{UnitRange{Int}}
    if isempty(one) || isempty(other) || one.stop < other.start || other.stop < one.start
        return [one]
    end
    if other.start <= one.start
        return [(other.stop + 1):(one.stop)]
    elseif other.stop >= one.stop
        return [(one.start):(other.start - 1)]
    else
        return [(one.start):(other.start - 1), (other.stop + 1):(one.stop)]
    end
    return []
end

"""
Get the absolute byte range in the source file for the given relative range to the SyntaxNode.
"""
function normalize_range(base_node::SyntaxNode, relative_range::UnitRange)::UnitRange{Int}
    start = relative_range.start + base_node.position - 1
    stop = relative_range.stop + base_node.position - 1
    return start:stop
end

"""
Combine several ranges into one continuous range spanning all of them.
"""
function combine_ranges(ranges::Vector{UnitRange{Int}})::UnitRange{Int}
    if isempty(ranges)
        return 1:0
    end
    nonempty_ranges = filter(r -> !isempty(r), ranges)
    s = minimum((r -> r.start).(nonempty_ranges))
    e = maximum((r -> r.stop).(nonempty_ranges))
    return s:e
end

end # module WhitespaceHelpers
