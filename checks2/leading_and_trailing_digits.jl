module LeadingAndTrailingDigits

include("_common.jl")

using JuliaSyntax: sourcetext

struct Check <: Analysis.Check end
id(::Check) = "leading-and-trailing-digits"
severity(::Check) = 3
synopsis(::Check) = "Floating-point numbers should always have one digit before the decimal point and at least one after"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"Float", n -> checkFloatNode(this, ctxt, n))
end

function checkFloatNode(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    text = sourcetext(node)
    index = findfirst('.', text)    

    if ! isnothing(index) && (index == 1 || index == length(text))
        report_violation(ctxt, this, node, "Bad floating-point style: $text")
    end
end

end # module LeadingAndTrailingDigits
