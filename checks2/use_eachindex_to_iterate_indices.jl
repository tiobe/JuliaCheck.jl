module UseEachindexToIterateIndices

include("_common.jl")

using JuliaSyntax: filename
using ...Properties: get_iteration_parts, is_loop, is_range, is_stop_point

struct Check <: Analysis.Check end
id(::Check) = "use-eachindex-to-iterate-indices"
severity(::Check) = 5
synopsis(::Check) = "Use eachindex() instead of a constructed range for iteration over a collection."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"ref", node -> check(this, ctxt, node))
end

function check(this::Check, ctxt::AnalysisContext, index_ref::SyntaxNode)
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
        report_violation(ctxt, this, loop_var, synopsis(this))
    end
end

end # module UseEachindexToIterateIndices
