module SpaceAroundBinaryInfixOperators

using ...Analysis: find_greenleaf
using JuliaSyntax: @KSet_str, GreenNode, is_infix_op_call, is_prefix_op_call, SourceFile, JuliaSyntax as JS
using ...Properties: is_infix_operator, is_type_op
using ...SyntaxNodeHelpers

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "space-around-binary-infix-operators"
severity(::Check) = 7
synopsis(::Check) = "Selected binary infix operators and the = character are followed and preceded by a single space."

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, node_applicable, node -> check_ws(this, ctxt, node))
    return nothing
end

function node_applicable(node::SyntaxNode)::Bool
    if !is_infix_operator(node) ||
        is_type_op(node) ||
        kind(node.parent) in KSet"parameters" ||
        kind(node) in KSet". :"
        return false
    end
    return true
end

function check_ws(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    code = node.source.code
    exception_kinds = ["^", ":", "."]
    op_node = get_op_node(node)
    no_space = any(a -> kind(a) == K"ref", ancestors(node)) || get_operator_string(op_node) ∈ exception_kinds
    op_ranges = find_operator_ranges(node)
    for op_range in op_ranges
        if !isnothing(op_range)
            expected_ws_length = no_space ? 0 : 1
            start_whitespace = find_whitespace_range(code, op_range.start, false)
            end_whitespace = find_whitespace_range(code, op_range.stop, true)

            full_range = char_range(node.source, combine_ranges([start_whitespace, op_range, end_whitespace]))
            full_text = JS.view(node.source, full_range)

            if (contains(full_text, '\n') || contains(full_text, '\r'))
                continue
            end
            if !whitespace_ok(start_whitespace, expected_ws_length, node.source) || !(whitespace_ok(end_whitespace, expected_ws_length, node.source) || has_comment_after(end_whitespace, node.source))
                msg = "Expected $(no_space ? "no" : "single") whitespace around '$(JS.view(node.source, op_range))'."
                report_violation(ctxt, this,
                    source_location(node.source, full_range.start),
                    char_range(node.source, full_range),
                    msg
                )
            end
        end
    end
    return nothing
end

function whitespace_ok(whitespace_range::UnitRange{Int}, expected_length::Int, source::SourceFile)::Bool
    text = JS.view(source, whitespace_range)
    if contains(text, '\n')
        return true # If whitespace spans multiple lines, rule does not apply
    end
    return length(whitespace_range) == expected_length
end

function has_comment_after(range::UnitRange, source::SourceFile)::Bool
    fixedrange = char_range(source, range)
    next_char = fixedrange.stop < lastindex(source.code) ? source.code[fixedrange.stop+1] : ' '
    return next_char == '#'
end

"""
Convert byte range to character range in given source file.
"""
function char_range(source::JS.SourceFile, byte_range::UnitRange{Int})::UnitRange{Int}
    if length(byte_range) == 0
        return range(thisind(source, byte_range.start); length=0)
    end
    return thisind(source, byte_range.start):thisind(source, byte_range.stop)
end

"""
Find all byte ranges of the operator in the given SyntaxNode.
"""
function find_operator_ranges(node::SyntaxNode)::Vector{UnitRange{Int}}
    if kind(node) == K"dotcall"
        dotranges = find_dotcall_ranges(node)
        if !isempty(dotranges)
            return dotranges
        end
    end
    return find_operator_token_ranges(node)
end

"""
Find byte ranges of all occurrences of the operator in the given SyntaxNode. (e.g. in case of chained operators like a + b + c)
"""
function find_operator_token_ranges(node::SyntaxNode)::Vector{UnitRange{Int}}
    main_operator_node = node |> get_op_node
    node_text = JS.sourcetext(node)
    base_range = JS.byte_range(node)
    if JS.is_leaf(node)
        return [JS.byte_range(main_operator_node)]
    end
    child_ranges = map(JS.byte_range, node.children)

    relevant_ranges = difference(base_range, child_ranges)
    if main_operator_node !== node
        push!(relevant_ranges, JS.byte_range(main_operator_node))
    end
    sn_kind_text = get_operator_string(main_operator_node)

    tokens::Vector{JS.Token} = JS.tokenize(node_text; operators_as_identifiers=false)
    tokens_with_kind = filter(t -> operator_matches(t, sn_kind_text, node_text), tokens)
    tokens_with_normalized_ranges = [(t, normalize_range(node, t.range)) for t in tokens_with_kind]
    filtered_tokens = filter(t -> any(r -> normalize_range(node, t.range) ⊆ r, relevant_ranges), tokens_with_kind)
    return [normalize_range(node, t.range) for t in filtered_tokens]
end

function difference(one::UnitRange{Int}, others::Vector{UnitRange{Int}})::Vector{UnitRange{Int}}
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

function _difference(one::UnitRange{Int}, other::UnitRange{Int})::Vector{UnitRange{Int}}
    if isempty(one) || isempty(other) || one.stop < other.start || other.stop < one.start
        return [one]
    end
    if other.start <= one.start
        return [other.stop+1:one.stop]
    elseif other.stop >= one.stop
        return [one.start:other.start-1]
    else
        return [one.start:other.start-1, other.stop+1:one.stop]
    end
    return []
end

"""
Get the node representing the operator in an infix operation.
E.g. in `a + b`, return the node for `+`.
"""
function get_op_node(node::SyntaxNode)::SyntaxNode
    if is_infix_op_call(node) && numchildren(node) >= 2 && kind(node) != K"::"
        return node.children[2]
    else
        return node
    end
end

"""
Find the byte range of the dot and the following operator in a dotcall node.
E.g. in `a .+ b`, find the range of `.+`.
"""
function find_dotcall_ranges(node::SyntaxNode)::Vector{UnitRange{Int}}
    if kind(node) != K"dotcall"
        return []
    end
    # Only check direct children, to avoid matching nested dotcalls
    g_cs = node.raw.children
    dot_idx = findfirst(c -> kind(c) == K".", g_cs)
    op_idx = nextind(g_cs, dot_idx)
    _, rel_start_pos, _ = JS.child_position_span(node.raw, dot_idx)
    _, rel_end_pos, end_span = JS.child_position_span(node.raw, op_idx)
    return [normalize_range(node, rel_start_pos:rel_end_pos + end_span - 1)]
end

"""
Find the range of whitespace starting from `start_idx` and going either forward or backward.
"""
function find_whitespace_range(text::AbstractString, start_idx::Int, forward::Bool)::UnitRange{Int}
    find = forward ? nextind : prevind
    first_find = find(text, start_idx)
    p = first_find
    last_find = nothing

    while checkbounds(Bool, text, p) && isspace(text[p])
        last_find = p
        p = find(text, p)
    end

    if isnothing(first_find) || isnothing(last_find)
        return range(first_find; length=0)
    elseif forward
        return first_find:last_find
    else # backward
        return last_find:first_find
    end
    return range(1; length=0) # should not happen
end

"""
Return true if the given token matches the given operator kind string representation.
"""
function operator_matches(token::JS.Token, sn_kind_text::AbstractString, text::AbstractString)::Bool
    untokenized_t = get_operator_string(token, text)
    return untokenized_t == sn_kind_text
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
Get the string representation of the operator represented by the given SyntaxNode.
This is needed because operators are parsed with kind Identifier, and we need to get the actual operator type.
"""
function get_operator_string(node::SyntaxNode)::String
    if node.val isa Symbol
        return String(node.val)
    else
        return kind(node) |> string
    end
end

function get_operator_string(token::JS.Token, text::AbstractString)::String
    return JS.untokenize(token, text)
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

end # module SpaceAroundBinaryInfixOperators
