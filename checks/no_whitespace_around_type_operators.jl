module NoWhitespaceAroundTypeOperators

import JuliaSyntax: GreenNode, @K_str, is_whitespace, kind, children, span,
                    source_location
using ...Checks: is_enabled
using ...Properties: lines_count, report_violation, source_column, source_index

const SEVERITY = 7
const RULE_ID = "asml-no-whitespace-around-type-operators"
const USER_MSG = "Omit white spaces around this operator."
const SUMMARY = "No whitespace around :: or <:."

function check(node::GreenNode)
    if !is_enabled(RULE_ID) return nothing end

    function same_kind(x) return kind(x) == kind(node) end
    expr = children(node)
    op_node = findfirst(same_kind, expr)
    if isnothing(op_node)
        @debug "Operator token not found inside operator expression subtree." node
        # Should be an assert, IMHO, but there is a bug(?); see here:
        # https://github.com/JuliaLang/JuliaSyntax.jl/issues/555
        # Not possible to solve at the moment, because we don't have a way to
        # implement function get_text_of_identifier below:
        #   same_token(x) = string(kind(node)) == get_text_of_identifier(x)
        #   op_node = findfirst(same_token, expr)
        return nothing
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
        offset::Int = sum(span.(expr[1:op_node])) - 2   # accounts for length of operator itself
        report_violation(index = source_index() + offset, len = 2,
                         line = lines_count(), col = source_column() + offset,
                         severity = SEVERITY, rule_id = RULE_ID,
                         user_msg = USER_MSG, summary = SUMMARY)
    end
end


end
