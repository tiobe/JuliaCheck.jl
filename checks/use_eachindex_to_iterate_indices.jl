module UseEachindexToIterateIndices

import JuliaSyntax: SyntaxNode, @K_str, haschildren, kind, numchildren
using ...Checks: is_enabled
using ...Properties: NullableNode, children, first_child, is_loop, is_range, is_stop_point,
                     report_violation

const SEVERITY = 5
const RULE_ID = "use-eachindex-to-iterate-indices"
const SUMMARY = "Use eachindex instead of a constructed range for iteration over a collection."
const USER_MSG = "Use `eachindex` instead of creating a range to iterate over."

function check(for_loop::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(for_loop) == K"for" "Expected a [for] node, got $(kind(for_loop))."

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
    if numchildren(node) != 2
        @debug "for loop [iteration/in] does not have exactly two children:" for_loop
        return nothing
    end
    loop_var, iterator = children(node)
    if is_range(iterator)
        # If the variable over that range is used to index an array,
        # we should report a violation.
    end
end

function is_index(var_name::String, loop::SyntaxNode)::Bool
    @assert is_loop(loop) "Expected a loop node, got $(kind(loop))."

    # Find the index variable in the loop
    for child in children(loop)
        if kind(child) == K"ref" && haschildren(child)
            coll, index = children(child)
            if (kind(coll) == K"Identifier" && kind(index) == K"Identifier" &&
                string(index) == var_name
                )
                return true
            end
        end
    end
    # TODO cancel this deep search. Revert to checking from a [ref] node.
    return false
end

function xxx(index_ref::SyntaxNode)::NullableNode
    @assert kind(index_ref) == K"ref" "Expected a [ref] node, got $(kind(index_ref))."
    coll, index = children(index_ref)
    if kind(coll) != K"Identifier"
        @debug "1st child of [ref] is not [Identifier]" index_ref
        return nothing
    end
    coll_name = string(coll)
    if kind(index) == K"Identifier"
        return index

    elseif kind(index) == K"call"
        for child in children(index)
            if (kind(child) == K"Identifier" && 
                string(child) ∉ ["length", "size", "end", ":", coll_name])

               return child
            end
        end
        return nothing
    end
end

end
