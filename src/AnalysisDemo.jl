# This file demonstrates the proposed Check and AnalysisContext types that are more in line with Roslyn analysis
# Checks implementing the Check type are in check2 directory
using InteractiveUtils

include("../src/printers/HighlightingViolationPrinter.jl")
include("Properties.jl");
include("SymbolTable.jl")
include("Analysis.jl")
include("Output.jl")
include("SyntaxNodeHelpers.jl")

Analysis.discover_checks()

using JuliaSyntax: SourceFile
using .Analysis
using .Properties

global checks = map(c -> c(), subtypes(Check))
global checks1 = filter(c -> id(c) === "avoid-extraneous-whitespace-between-open-and-close-characters", checks)

filename = "dummy.jl"
text = """
    println( "test")
    ham[ 1  2  [3  4] ]
    a = [ 1, 2,  4]
    f(; x = 10)
"""
sourcefile = SourceFile(text, filename=filename)
printer = JuliaCheck.Output.ViolationPrinter.HighlightingViolationPrinter
violations = run_analysis(sourcefile, checks1; print_ast=true, print_llt=true)
output_file_arg = ""
print_violations(printer, output_file_arg, violations)
