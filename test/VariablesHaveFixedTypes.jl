# Bad
function change_type_1()::Float64
    x = 1
    x = 2.0
    return x
end

function change_type_2()
    x = 5
    x = x/2
    y = x^2
    return y
end

function change_type_3()
    x = 5
    x = string(x)
    y = x * "_suffix"
    return y
end

# Good
function _check(this::Check, ctxt::AnalysisContext, sf::SourceFile)::Nothing
    for i in eachindex(ctxt.greenleaves)
        expected_spaces = nothing
        if sourcetext(ctxt.greenleaves[i-1]) ∈ ("[", "(", "{", "=")
            expected_spaces = 0 # No space after open delimiter
        elseif sourcetext(ctxt.greenleaves[i+1]) ∈ ("]", ")", "}", "=", ";", ",")
            expected_spaces = 0 # No space before close delimiter
        else
            expected_spaces = 1 # Exactly one space between elements
        end
    end
    return nothing
end