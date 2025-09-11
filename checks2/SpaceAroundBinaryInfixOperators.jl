module SpaceAroundBinaryInfixOperators

include("_common.jl")

using ...Properties: is_infix_operator
using ...SyntaxNodeHelpers
using JuliaSyntax: @KSet_str, GreenNode, is_infix_op_call, is_prefix_op_call, JuliaSyntax as JS

struct Check<:Analysis.Check end
id(::Check) = "space-around-binary-infix-operators"
severity(::Check) = 7
synopsis(::Check) = "Selected binary infix operators and the = character are followed and preceded by a single space."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_infix_operator, node -> check_ws(this, ctxt, node))
end

function check_ws(this, ctxt, node::SyntaxNode)
    code = node.source.code
    exception_kinds = KSet":: ^ . :"
    no_space = any(a -> kind(a) == K"ref", ancestors(node)) || kind(get_op_node(node)) in exception_kinds || get_operator_string(get_op_node(node)) == "^"
    op_ranges = find_operator_ranges(node)
    for op_range in op_ranges
        if !isnothing(op_range)
            expected_ws_length = no_space ? 0 : 1
            start_whitespace = find_whitespace_range(code, op_range.start, false)
            end_whitespace = find_whitespace_range(code, op_range.stop, true)

            full_range = char_range(node.source, combine_ranges([start_whitespace, op_range, end_whitespace]))

            if length(start_whitespace) != expected_ws_length || length(end_whitespace) != expected_ws_length # skip check if range contains a newline
                msg = "Expected $(no_space ? "no" : "single") whitespace around '$(code[char_range(node.source, op_range)])'."
                report_violation(ctxt, this,
                    source_location(node.source, full_range.start),
                    full_range,
                    msg
                )
            end
        end
    end
end

"""
Convert byte range to character range in given source file.
"""
function char_range(file::JS.SourceFile, range::UnitRange{Int})::UnitRange{Int}
    range.start:thisind(file, range.stop)
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
    node_text = JS.sourcetext(node)
    sn_kind_text = node |> get_op_node |> get_operator_string
    tokens::Vector{JS.Token} = JS.tokenize(node_text, operators_as_identifiers=false)
    filtered_tokens = filter(t -> operator_matches(t, sn_kind_text, node_text), tokens)
    return [get_span(node, t.range.start - 1:t.range.stop - 1) for t in filtered_tokens]
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
    return [get_span(node, rel_start_pos - 1:rel_end_pos + end_span - 2)]
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
        return range(first_find, length=0)
    elseif forward
        return first_find:last_find
    else # backward
        return last_find:first_find
    end
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
function get_span(base_node::SyntaxNode, relative_range::UnitRange)::UnitRange{Int}
    start = relative_range.start + base_node.position
    stop = relative_range.stop + base_node.position
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
