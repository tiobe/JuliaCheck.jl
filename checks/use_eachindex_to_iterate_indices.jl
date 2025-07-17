module UseEachindexToIterateIndices

import JuliaSyntax: SyntaxNode, @K_str, kind, numchildren
using ...Checks: is_enabled
using ...Properties: NullableNode, children, first_child, get_iteration_parts,
                     haschildren, is_loop, is_range, is_stop_point,
                     report_violation

const SEVERITY = 5
const RULE_ID = "use-eachindex-to-iterate-indices"
const SUMMARY = "Use eachindex instead of a constructed range for iteration over a collection."
const USER_MSG = "Use `eachindex` instead of creating a range to iterate over."

function check(index_ref::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(index_ref) == K"ref" "Expected a [ref] node, got $(kind(index_ref))."

    for_loop = index_ref.parent
    while !( isnothing(for_loop) || is_loop(for_loop) || is_stop_point(for_loop) )
        for_loop = for_loop.parent
    end
    if isnothing(for_loop) || kind(for_loop) != K"for"
        # Did not find a [for] loop containing the array indexing.
        return nothing
    end

    loop_var, loop_expr = get_iteration_parts(for_loop)
    if !isnothing(loop_var) && is_range(loop_expr)
        report_violation(loop_var;
                         severity = SEVERITY, rule_id = RULE_ID,
                         summary = SUMMARY, user_msg = USER_MSG)
    end
end

end
