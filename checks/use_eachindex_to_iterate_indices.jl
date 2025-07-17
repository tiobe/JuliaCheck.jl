module UseEachindexToIterateIndices

import JuliaSyntax: SyntaxNode, @K_str, kind, numchildren
using ...Checks: is_enabled
using ...Properties: NullableNode, children, first_child, haschildren, is_loop,
                     is_range, is_stop_point, report_violation

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

    if !( haschildren(for_loop) &&
          kind(first_child(for_loop)) == K"iteration"
       )
        @debug "for loop does not have an [iteration]" for_loop
        return nothing
    end
    node = first_child(for_loop)
    if !( haschildren(node) && kind(first_child(node)) == K"in" )
        @debug "for loop does not have an [iteration]/[in] sequence:" for_loop
        return nothing
    end
    node = first_child(node)
    if numchildren(node) != 2
        @debug "for loop [iteration/in] does not have exactly two children:" for_loop
        return nothing
    end
    loop_var, loop_expr = children(node)
    if is_range(loop_expr)
        report_violation(loop_var;
                         severity = SEVERITY, rule_id = RULE_ID,
                         summary = SUMMARY, user_msg = USER_MSG)
    end
end

end
