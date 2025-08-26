# This file demonstrates the proposed Check and AnalysisContext types that are more in line with Roslyn analysis
# Checks implementing the Check type are in check2 directory
using InteractiveUtils

include("Analysis.jl")
include("LosslessTrees.jl")
include("Properties.jl");
include("ViolationPrinters.jl")
include("SyntaxNodeHelpers.jl")

Analysis.load_all_checks2()

using JuliaSyntax: SourceFile
using .Analysis
using .ViolationPrinters
using .Properties

global checks = map(c -> c(), subtypes(Check))
global checks1 = filter(c -> id(c) === "do-not-nest-multiline-comments", checks)
if isempty(checks1) 
    @error "No checks!"
end
 
filename = "dummy.jl"
text = """
 ##=#= Not a multiline comment =#=#
"""
Properties.SF = SourceFile(text, filename=filename)
run_analysis(text, checks1;
    filename=filename, print_ast=true, print_llt=true, violationprinter=highlighting_violation_printer)

