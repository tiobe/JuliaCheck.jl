module UseEachindexToIterateIndices

import JuliaSyntax: SyntaxNode, @K_str, haschildren, kind
using ...Checks: is_enabled
using ...Properties: NullableNode, children, first_child, is_loop, is_stop_point,
                     report_violation

const SEVERITY = 5
const RULE_ID = "use-eachindex-to-iterate-indices"
const SUMMARY = "Use eachindex instead of a constructed range for iteration over a collection."
const USER_MSG = "Use `eachindex` instead of creating a range to iterate over."

function check(index_ref::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert kind(index_ref) == K"ref" "Expected a [ref] node, got $(kind(index_ref))."

    loop = index_ref.parent
    while !( isnothing(loop) || is_loop(loop) || is_stop_point(loop) )
        loop = loop.parent
    end
    if isnothing(loop) || !is_loop(loop)
        # Did not find a loop containing an array indexing.
        return nothing
    end

    # Get the index variable
    index_var = find_index_variable(index_ref)
    if isnothing(index_var)
        @debug "Couldn't find index variable in $index_ref"
        return nothing
    end

    if (kind(loop) == K"while" &&
            is_index_var_in_while_condition(loop, string(index_var))) ||
       (kind(loop) == K"for" &&
            ! looping_over_eachindex(loop, index_var))

        report_violation(index_var;
                         severity = SEVERITY, rule_id = RULE_ID,
                         summary = SUMMARY, user_msg = USER_MSG)
    end
end

function find_index_variable(index_ref::SyntaxNode)::NullableNode
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

function is_index_var_in_while_condition(loop::SyntaxNode, var_name::AbstractString)::Bool
    @assert kind(loop) == K"while" "Expected a [while] node, got $(kind(loop))."
    return _is_index_var_in_while_cond(loop, var_name)
end
function _is_index_var_in_while_cond(node::SyntaxNode, var_name::AbstractString)::Bool
    if !haschildren(node)
        return false
    end
    for child in children(node)
        ids = filter(x -> kind(x) == K"Identifier", children(child))
        if var_name ∈ map(string, ids)
            return true
        end
    end
    return any(x -> _is_index_var_in_while_cond(x, var_name), children(node))
end


function looping_over_eachindex(loop::SyntaxNode, index_var::SyntaxNode)::Bool
    @assert kind(loop) == K"for" "Expected a [for] node, got $(kind(loop))."
    @assert kind(index_var) == K"Identifier" "Expected an [Identifier] node, got $(kind(index_var))."

    if !( kind(first_child(loop)) == K"iteration" ||
          haschildren(loop) ||
          kind(first_child(first_child(loop))) == K"in")
        @debug "for loop does not have an [iteration]/[in] sequence:" loop
        return false
    end

    loop_var, iterator = children(first_child(first_child(loop)))

    if string(loop_var) != string(index_var)
        @debug "Loop variable $loop_var does not match index variable $index_var in loop: $loop"
        # What TODO here?
        return false
    end

    if kind(iterator) == K"Identifier"
        @debug """Iterating with a collection's iterator. Thus, the index found in the loop body
                must be 'hand-made', which is bad.""" iterator
        # TODO Investigate further or assume that?
        return false

    elseif kind(iterator) == K"call"
        return kind(first_child(iterator)) == K"Identifier" &&
                string(first_child(iterator)) == "eachindex"

    else
        @debug "Unexpected kind of iterator in [for] loop: $(kind(iterator))" iterator
        return nothing
    end
end

end # UseEachindexToIterateIndices
