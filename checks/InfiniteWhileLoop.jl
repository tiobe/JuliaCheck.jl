module InfiniteWhileLoop

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "infinite-while-loop"
Analysis.severity(::Check) = 5
Analysis.synopsis(::Check) = "Do not use while true"

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"while", n -> _check_while_node(this, ctxt, n))
end

function _check_while_node(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    @assert kind(node) == K"while" "Expected a [while], got $(kind(node))"
    @assert numchildren(node) > 0 "A [while] without children! Is this an incomplete tree, from code under edition?"
    condition = children(node)[1]
    if kind(condition) == K"Bool" && string(condition) == "true"
        report_violation(ctxt, this, condition, "Implement a proper stop criterion for this while loop.")
    end

    return nothing
end

end # module InfiniteWhileLoop

