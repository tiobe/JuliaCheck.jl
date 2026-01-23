module SpaceAroundBinaryInfixOperators

using JuliaSyntax:
    @KSet_str,
    is_infix_op_call,
    SourceFile,
    JuliaSyntax as JS
using ...Properties: is_infix_operator, is_type_op
using ...SyntaxNodeHelpers: ancestors
using ...WhitespaceHelpers:
    char_range,
    followed_by_comment,
    difference,
    normalize_range,
    combine_ranges,
    find_whitespace_range

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "space-around-binary-infix-operators"
Analysis.severity(::Check) = 7
Analysis.synopsis(::Check) = "Selected binary infix operators and the = character are followed and preceded by a single space."

"""
Kinds for which the rule will assert no whitespace surrounds them
"""
const NO_WHITESPACE_KINDS = ["^"]
"""
Kinds for which the surrounding whitespace is not checked
"""
const EXCLUDED_KINDS = [":", "."]

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(
        ctxt,
        _node_applicable,
        node -> _check_whitespace(this, ctxt, node)
    )
    return nothing
end

function _node_applicable(node::SyntaxNode)::Bool
    if !is_infix_operator(node) ||
            is_type_op(node) ||
            kind(node.parent) in KSet"parameters" ||
            _get_operator_string(_get_op_node(node)) in EXCLUDED_KINDS
        return false
    end
    return true
end

function _check_whitespace(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    op_node = _get_op_node(node)
    no_space =
        any(a -> kind(a) == K"ref", ancestors(node)) ||
        _get_operator_string(op_node) ∈ NO_WHITESPACE_KINDS
    op_ranges = _find_operator_ranges(node)
    for op_range in op_ranges
        if !isnothing(op_range)
            expected_ws_length = no_space ? 0 : 1
            start_whitespace = find_whitespace_range(node.source.code, op_range.start, forward=false)
            end_whitespace = find_whitespace_range(node.source.code, op_range.stop, forward=true)

            start_ws_ok = _whitespace_ok(start_whitespace, expected_ws_length, node.source)
            end_ws_ok = (
                _whitespace_ok(end_whitespace, expected_ws_length, node.source) ||
                followed_by_comment(end_whitespace, node.source)    # Whitespace before inline comment is allowed
            )

            if !(start_ws_ok && end_ws_ok)
                full_range = char_range(
                    node.source,
                    combine_ranges([start_whitespace, op_range, end_whitespace])
                )
                msg = "Expected $(no_space ? "no" : "single") whitespace around '$(JS.view(node.source, op_range))'."
                report_violation(
                    ctxt,
                    this,
                    source_location(node.source, full_range.start),
                    char_range(node.source, full_range),
                    msg
                )
            end
        end
    end
    return nothing
end

function _whitespace_ok(
    whitespace_range::UnitRange{Int},
    expected_length::Int,
    source::SourceFile
)::Bool
    text = JS.view(source, whitespace_range)
    if contains(text, '\n')
        return true # If whitespace spans multiple lines, rule does not apply
    end
    return length(whitespace_range) == expected_length
end

"""
Find all byte ranges of the operator in the given SyntaxNode.
"""
function _find_operator_ranges(node::SyntaxNode)::Vector{UnitRange{Int}}
    if kind(node) == K"dotcall"
        dotrange = _find_dotcall_range(node)
        if !isnothing(dotrange)
            return [dotrange]
        end
    end
    return _find_operator_token_ranges(node)
end

"""
Find byte ranges of all occurrences of the operator in the given SyntaxNode. (e.g. in case of chained operators like a + b + c)
"""
function _find_operator_token_ranges(node::SyntaxNode)::Vector{UnitRange{Int}}
    main_operator_node = node |> _get_op_node

    node_text = JS.sourcetext(node)
    base_range = JS.byte_range(node)

    if JS.is_leaf(node)
        return [JS.byte_range(main_operator_node)]
    end
    child_ranges = map(JS.byte_range, node.children)

    # Ranges not covered by child SyntaxNodes contain trivia for current node
    non_child_ranges = difference(base_range, child_ranges)
    if main_operator_node !== node
        push!(non_child_ranges, JS.byte_range(main_operator_node))
    end

    operator_string = _get_operator_string(main_operator_node)
    tokens::Vector{JS.Token} = JS.tokenize(node_text; operators_as_identifiers=false)
    filtered_tokens = filter(
        t ->
            _token_is_operator(t, operator_string, node_text) &&
                any(r -> normalize_range(node, t.range) ⊆ r, non_child_ranges),
        tokens
    )
    return [normalize_range(node, t.range) for t in filtered_tokens]
end

"""
Get the node representing the operator in an infix operation.
E.g. in the node for `a + b`, return the node representing `+`.
"""
function _get_op_node(node::SyntaxNode)::SyntaxNode
    if is_infix_op_call(node) && numchildren(node) >= 2
        return node.children[2]
    else
        return node
    end
end

"""
Find the byte range of the dot and the following operator in a dotcall node.
E.g. in `a .+ b`, find the range of `.+`.
"""
function _find_dotcall_range(node::SyntaxNode)::Union{UnitRange{Int}, Nothing}
    if kind(node) != K"dotcall"
        return nothing
    end
    # Only check direct children, to avoid matching nested dotcalls
    g_cs = node.raw.children
    dot_idx = findfirst(c -> kind(c) == K".", g_cs)
    op_idx = nextind(g_cs, dot_idx)
    _, rel_start_pos, _ = JS.child_position_span(node.raw, dot_idx)
    _, rel_end_pos, end_span = JS.child_position_span(node.raw, op_idx)
    dotcall_range = (rel_start_pos):(rel_end_pos + end_span - 1)
    return normalize_range(node, dotcall_range)
end

"""
Return true if the given token matches the given operator kind string representation.
"""
function _token_is_operator(
    token::JS.Token,
    sn_kind_text::AbstractString,
    text::AbstractString
)::Bool
    token_text = JS.untokenize(token, text)
    return token_text == sn_kind_text
end

"""
Get the string representation of the operator represented by the given SyntaxNode.
This is needed because operators are parsed with kind Identifier, and we need to get the actual operator type.
"""
function _get_operator_string(node::SyntaxNode)::String
    if node.val isa Symbol
        return String(node.val) # For operators with kind Identifier, get the operator type from the 'val' field.
    else
        return kind(node) |> string
    end
end

end # module SpaceAroundBinaryInfixOperators
