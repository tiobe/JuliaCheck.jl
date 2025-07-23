module NoWhitespaceAroundTypeOperators

import JuliaSyntax: @K_str, is_whitespace, kind
using ...Checks: is_enabled
using ...Properties: report_violation
using ...LosslessTrees: LosslessNode, children, get_source_text,
                        get_start_coordinates, start_index

const SEVERITY = 7
const RULE_ID = "no-whitespace-around-type-operators"
const USER_MSG = "Omit white spaces around this operator."
const SUMMARY = "No whitespace around :: or <:."

function check(node::LosslessNode)
    if !is_enabled(RULE_ID) return nothing end

    function same_kind(x) return kind(x) == kind(node) end
    expr = children(node)
    op_node = findfirst(same_kind, expr)
    if isnothing(op_node)
        # See here: # https://github.com/JuliaLang/JuliaSyntax.jl/issues/555
        # But we can still check the node's text.
        function same_op(x::LosslessNode) return x.text == node.text end
        op_node = findfirst(same_op, expr)
        if isnothing(op_node)
            @debug "Operator token not found inside operator expression subtree." node
            return nothing
        end
    end
    if kind(node) == K"::"
        before = op_node == 1 ? K"(" : expr[op_node - 1]
        after  = op_node == length(expr) ? K")" : expr[op_node + 1]
        if kind(after) == K"curly"
            after = children(after)[1]
        end

    elseif kind(node) == K"<:"
        before = op_node == 1 ? K"{" : expr[op_node - 1]
        after  = expr[op_node + 1]

    elseif kind(node) == K">:"
        before = expr[op_node - 1]
        after = op_node == length(expr) ? K"}" : expr[op_node + 1]
    end

    if any(is_whitespace, [before, after])
        offset::Int = sum(length.(expr[1:op_node])) - 2     # accounts for length of operator itself
        ln, cl = get_start_coordinates(node)
        report_violation(; index = start_index(node) + offset, len = 2,
                         line = ln, col = cl + offset,
                         severity = SEVERITY, rule_id = RULE_ID,
                         user_msg = USER_MSG, summary = SUMMARY)
    end
end


end
