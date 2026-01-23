module LeadingAndTrailingDigits

include("_common.jl")

using JuliaSyntax: sourcetext

struct Check<:Analysis.Check end
Analysis.id(::Check) = "leading-and-trailing-digits"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Floating-point numbers should always have one digit before the decimal point and at least one after"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, n -> kind(n) == K"Float", n -> _check_float_node(this, ctxt, n))
    return nothing
end

function _check_float_node(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    text = sourcetext(node)
    index = findfirst('.', text)

    if ! isnothing(index) && (index == 1 || index == length(text))
        report_violation(ctxt, this, node, "Bad floating-point style: $text")
    end
    return nothing
end

end # module LeadingAndTrailingDigits
