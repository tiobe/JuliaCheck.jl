# This file can be used to invoke a single rule on a piece of code, useful during development
using InteractiveUtils

using JuliaCheck

using JuliaSyntax: SourceFile
using JuliaCheck.Analysis
using JuliaCheck.Analysis: Check, id
using JuliaCheck.Output: print_violations

global checks = map(c -> c(), subtypes(Check))
target_check = "type-names-upper-camel-case"
global checks1 = filter(c -> id(c) === target_check, checks)
@assert length(checks1) == 1

text = """
struct transX end
struct TransX end
"""

sourcefile = SourceFile(text, filename="dummy.jl")
printer = JuliaCheck.Output.select_violation_printer("highlighting")
violations = Analysis.run_analysis(sourcefile, checks1; print_ast=true, print_llt=true)
output_file_arg = ""
print_violations(printer, output_file_arg, violations)
