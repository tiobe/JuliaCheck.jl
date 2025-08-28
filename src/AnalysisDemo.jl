# This file demonstrates the proposed Check and AnalysisContext types that are more in line with Roslyn analysis
# Checks implementing the Check type are in check2 directory
using InteractiveUtils

include("Properties.jl");
include("SymbolTable.jl")
include("Analysis.jl")
include("ViolationPrinters.jl")
include("SyntaxNodeHelpers.jl")

Analysis.discover_checks()

using JuliaSyntax: SourceFile
using .Analysis
using .ViolationPrinters
using .Properties

global checks = map(c -> c(), subtypes(Check))
global checks1 = filter(c -> id(c) === "indentation-levels-are-four-spaces", checks)
 
filename = "dummy.jl"
text = """
    ham[ 1  2  [3  4] ]
    \"\"\"
       f( ; x = 10 )
    \"\"\"
"""
sourcefile = SourceFile(text, filename=filename)
run_analysis(sourcefile, checks1; print_ast=true, print_llt=true, 
    violationprinter=highlighting_violation_printer)

