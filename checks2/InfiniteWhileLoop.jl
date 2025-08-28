module InfiniteWhileLoop

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "infinite-while-loop"
severity(::Check) = 5
synopsis(::Check) = "Do not use while true"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"while", n -> checkWhileNode(this, ctxt, n))
end

function checkWhileNode(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    @assert kind(node) == K"while" "Expected a [while], got $(kind(node))"
    @assert numchildren(node) > 0 "A [while] without children! Is this an incomplete tree, from code under edition?"
    condition = children(node)[1]
    if kind(condition) == K"Bool" && string(condition) == "true"
        report_violation(ctxt, this, condition, "Implement a proper stop criterion for this while loop.")
    end
end

end # module InfiniteWhileLoop

