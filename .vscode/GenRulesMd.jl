using InteractiveUtils
using JuliaCheck: Analysis

"""
Prints table of all rules (ID and synopsis) in Markdown format.
"""
function rules()::Nothing
    available_checks = map(c -> c(), subtypes(Analysis.Check))
    for check in available_checks
        print("|`$(Analysis.id(check))`|$(Analysis.synopsis(check))|\n")
    end
end

rules()
