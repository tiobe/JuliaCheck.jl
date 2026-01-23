module UseEachindexToIterateIndices

include("_common.jl")

using JuliaSyntax: sourcetext
using ...Properties: get_iteration_parts, is_range
using ...SyntaxNodeHelpers: find_descendants

struct Check<:Analysis.Check end
Analysis.id(::Check) = "use-eachindex-to-iterate-indices"
Analysis.severity(::Check) = 5
Analysis.synopsis(::Check) = "Use eachindex() instead of a constructed range for iteration over a collection."

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"for", node -> _check(this, ctxt, node))
end

function _check(this::Check, ctxt::AnalysisContext, for_node::SyntaxNode)::Nothing
    @assert kind(for_node) == K"for" "Expected a [for] node, got $(kind(for_node))."

    loop_var, loop_expr = get_iteration_parts(for_node)
    if isnothing(loop_var) ||
        !is_range(loop_expr) # Only trigger when loop expression uses a 'range'
        return
    end

    for ref in find_descendants(n -> kind(n) == K"ref", for_node)
        if length(ref.children) == 2 && kind(ref.children[2]) == K"Identifier"
            collection = sourcetext(ref.children[1])
            index_var = ref.children[2] # Take the `index` in collection[index]

            # Do simple name resolution to check whether the loop variable is used as index variable
            if string(loop_var) == string(index_var)
                report_violation(ctxt, this, loop_expr,
                    "Use eachindex() instead of a constructed range for iteration over collection '$collection'"
                )

                # Return so that we report at most one violation per 'for' node
                return
            end
        end

    end
    return nothing
end

end # module UseEachindexToIterateIndices
