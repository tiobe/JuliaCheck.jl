module LeadingAndTrailingDigits

using JuliaSyntax: SyntaxNode, @K_str, kind, sourcetext
using ...Properties: report_violation

SEVERITY = 3
RULE_ID = "leading-and-trailing-digits"
USER_MSG = "Floating-point numbers should always have one digit before the decimal point and at least one after."
SUMMARY = "Leading and trailing digits."

function check(node::SyntaxNode)
    @assert kind(node) == K"Float" "This check only applies to [Float] nodes"
    text = sourcetext(node)
    index = findfirst('.', text)
    if ! isnothing(index) && (index == 1 || index == length(text))
        report_violation(node; severity = SEVERITY, rule_id = RULE_ID,
                               user_msg = USER_MSG, summary = SUMMARY)
    end
end

end
