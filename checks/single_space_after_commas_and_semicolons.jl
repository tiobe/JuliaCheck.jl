module SingleSpaceAfterCommasAndSemicolons

import JuliaSyntax: GreenNode, SyntaxNode, Kind, @K_str, is_whitespace, kind,
                    sourcetext, span
using ...Checks: is_enabled
using ...Properties: EOL, SF, haschildren, is_separator, lines_count,
                     report_violation, safe_index, source_column, source_index,
                     source_text
using ...LosslessTrees: LosslessNode, SourceSpan, children, end_index, fake_llt_node,
                        get_source_text, get_start_coordinates, start_index

const SEVERITY = 7
const RULE_ID = "single-space-after-commas-and-semicolons"
const USER_MSG = "A comma or a semicolon is followed, but not preceded, by a space."
const SUMMARY = "Commas and semicolons are followed, but not preceded, by a space."


function check(node::LosslessNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert is_separator(node) "Expected a [;] or [,] node, but got [$(kind(node))]."

    expr = children(node.parent)
    op_node = findfirst(x -> x == node, expr)
    if isnothing(op_node)
        @debug "Operator token not found inside operator expression subtree." node.parent
        return nothing
    end
    before = op_node == 1 ? make_llt_node(K"(", node, -1) : expr[op_node-1]
    after = op_node == length(expr) ? make_llt_node(K")", node, 1) : expr[op_node+1]

    if is_whitespace(before)
        report_it(before)
    end

    if haschildren(after) && is_whitespace(children(after)[1])
        after = children(after)[1]
    end
    if !is_whitespace(after)
        # I don't want to report node `after`, as it can be a lengthy declaration
        # of a parameter (identifier, type, default value, etc.). Just point to
        # the place where the space should be.
        y, x = get_start_coordinates(after)
        report_violation(; index = start_index(after), len = 0,
                         line = y, col = x,
                         severity = SEVERITY, rule_id = RULE_ID,
                         user_msg = USER_MSG, summary = SUMMARY)

    elseif span(after) > 1
        # There should be only one space...
        if kind(after) == K"NewlineWs"
            # ... unless it is a line break (followed by indentation)
            textual = get_source_text(after)
            # textual = source_text(parent_index + offset, len)
            line_break = Regex("$EOL[ \t]*")
            if occursin(line_break, textual)
                return nothing
            end
        end
        report_it(after)
    end
end

function report_it(node::LosslessNode)
    report_violation(node; severity = SEVERITY, rule_id = RULE_ID,
                           user_msg = USER_MSG, summary = SUMMARY)
end

function make_llt_node(kind::Kind, node::LosslessNode, delta::Integer)
    s = sourcetext(SF)
    span = SourceSpan(node.span.start_line, node.span.start_column + delta,
                      node.span.end_line, node.span.end_column + delta,
                      safe_index(s, start_index(node) + delta),
                      safe_index(s, node.span.end_offset + delta))
    return fake_llt_node(kind, span = span)
end

end
