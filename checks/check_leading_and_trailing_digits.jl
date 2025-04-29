module LeadingAndTrailingDigits

using JuliaSyntax: SyntaxNode, sourcetext

using ...Properties: report_violation

export check

function check(node::SyntaxNode)
    text = sourcetext(node)
    index = findfirst('.', text)
    if ! isnothing(index) && (index == 1 || index == length(text))
        report_violation(node, "Bad format for literal '$text'.",
                         "Floating-point numbers should always have one digit before the decimal point and at least one after.")
    end
end

end
