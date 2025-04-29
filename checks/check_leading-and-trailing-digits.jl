module LeadingAndTrailingDigits

using JuliaSyntax: SyntaxNode

using ...Properties: report_violation

export check

function check(node::SyntaxNode)
    text = string(node)
    index = findfirst('.', text)
    if ! isnothing(index) && (index == 1 || index == length(text))
        # Turns out this will never trigger, because of something going on inside
        # JuliaSyntax. See https://github.com/JuliaLang/JuliaSyntax.jl/issues/551
        report_violation()
    end
end

end
