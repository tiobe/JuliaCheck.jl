module SpaceAroundBinaryInfixOperators

include("_common.jl")

using ...Analysis: get_syntaxnode_text
using ...Properties: is_infix_operator
using ...SyntaxNodeHelpers
using JuliaSyntax: @KSet_str, GreenNode, is_infix_op_call, is_prefix_op_call, JuliaSyntax as JS

struct Check<:Analysis.Check end
id(::Check) = "space-around-binary-infix-operators"
severity(::Check) = 7
synopsis(::Check) = "Selected binary infix operators and the = character are followed and preceded by a single space."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_infix_operator, node -> begin
        code = node.source.code
        green_node = node.raw
        start_pos = prevind(code, node.position)
        end_pos = node.position + node.raw.span
        check_ws(this, ctxt, node)
    end)
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

            full_range = combine_ranges([start_whitespace, op_range, end_whitespace])

            if length(start_whitespace) != expected_ws_length || length(end_whitespace) != expected_ws_length # skip check if range contains a newline
                msg = "Expected $(no_space ? "no" : "single") whitespace around '$(node.source.code[op_range])'"
                report_violation(ctxt, this,
                    source_location(node.source, first(full_range)),
                        full_range,
                        msg
                    )
            end
        end
    end
end

"""
Find all occurrences of the operator in the given SyntaxNode. (e.g. in case of chained operators like a + b + c)
"""
function find_operator_ranges(node::SyntaxNode)::Vector{UnitRange{Int}}
    node_text = JS.sourcetext(node)
    sn_kind_text = node |> get_op_node |> get_operator_string
    tokens::Vector{JS.Token} = JS.tokenize(node_text, operators_as_identifiers=false)
    filtered_tokens = filter(t -> operator_matches(t, sn_kind_text, node_text), tokens)
    code = node.source.code
    res = UnitRange{Int}[]
    if kind(node.parent) == K"dotcall"
        if kind(node) != K"."
            return res
        end
        dotrange = find_dotcall_range(tokens)
        if !isnothing(dotrange)
            push!(res, prevind(code, dotrange.start + node.position):prevind(code, dotrange.stop + node.position))
            return res
        end
    end
    for t in filtered_tokens
        push!(res, prevind(code, t.range.start + node.position):prevind(code, t.range.stop + node.position))
    end
    return res
end

function find_dotcall_range(tokens::Vector{JS.Token})::Union{UnitRange{Int}, Nothing}
    for (i, t) in enumerate(tokens)
        if kind(t) == K"."
            nextt = i < length(tokens) ? tokens[i+1] : nothing
            if !isnothing(nextt)
                return t.range.start:nextt.range.stop
            end
        end
    end
    return nothing
end

function find_whitespace_range(text::AbstractString, start_idx::Integer, forward::Bool)::UnitRange
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

function get_op_node(node::SyntaxNode)::SyntaxNode
    if is_infix_op_call(node) && numchildren(node) >= 2 && kind(node) != K"::"
        return node.children[2]
    else
        return node
    end
end

function operator_matches(token::JS.Token, sn_kind_text::AbstractString, text::AbstractString)::Bool
    untokenized_t = get_operator_string(token, text)
    return untokenized_t == sn_kind_text
end

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
