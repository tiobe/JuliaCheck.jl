module UseEachindexToIterateIndices

include("_common.jl")

using ...Properties: get_iteration_parts, NullableNode, is_range, is_stop_point

struct Check<:Analysis.Check
    already_reported::Set{SyntaxNode}
    Check() = new(Set{SyntaxNode}())
end
id(::Check) = "use-eachindex-to-iterate-indices"
severity(::Check) = 5
synopsis(::Check) = "Use eachindex() instead of a constructed range for iteration over a collection."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"ref", node -> _check(this, ctxt, node))
end

"""
Given a array index syntax node `ref`,
this function searches upwards through the parent nodes to find an enclosing `for` loop
where the variable is defined as a loop iterator.
"""
function _find_enclosing_loop_binding(ref::SyntaxNode)::Tuple{NullableNode, NullableNode}
    if length(ref.children) == 2 && kind(ref.children[2]) == K"Identifier"
        ref_var = string(ref.children[2])
    else
        return (nothing, nothing)
    end
    n = ref;
    while !isnothing(n) && !is_stop_point(n)
        if kind(n) == K"for"
            loop_var, loop_expr = get_iteration_parts(n)
            if string(loop_var) == ref_var
                return (loop_var, loop_expr)
            end
        end
        n = n.parent
    end
    return (nothing, nothing)
end

function _check(this::Check, ctxt::AnalysisContext, index_ref::SyntaxNode)::Nothing
    @assert kind(index_ref) == K"ref" "Expected a [ref] node, got $(kind(index_ref))."

    (loop_var, loop_expr) = _find_enclosing_loop_binding(index_ref)
    if !isnothing(loop_var) && is_range(loop_expr)
        if loop_var ∉ this.already_reported
            push!(this.already_reported, loop_var)
            report_violation(ctxt, this, loop_var, synopsis(this))
        end
    end
    return nothing
end

end # module UseEachindexToIterateIndices
