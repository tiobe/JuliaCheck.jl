module LeadingAndTrailingDigits

using JuliaSyntax: SyntaxNode, @K_str, kind, sourcetext

using ...Properties: report_violation

export check

function check(node::SyntaxNode)
    @assert kind(node) == K"Float" "This check only applies to [Float] nodes"
    text = sourcetext(node)
    index = findfirst('.', text)
    if ! isnothing(index) && (index == 1 || index == length(text))
        report_violation(node, 3;
                         user_msg="Bad format for literal '$text'.",
                         summary="Floating-point numbers should always have one digit before the decimal point and at least one after.")
    end
end

end
