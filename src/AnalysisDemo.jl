# This file demonstrates the proposed Check and AnalysisContext types that are more in line with Roslyn analysis
# Checks implementing the Check type are in check2 directory
using InteractiveUtils

include("Analysis.jl")
include("LosslessTrees.jl")
include("Properties.jl");

Analysis.load_all_checks2()

using .Analysis
using JuliaSyntax

global checks = map(c -> c(), subtypes(Check))

 
run_analysis("""
TEST = .5
const global some_other_number = 42

function test(x)
    println("Hello World")
    INSIDE = .25 + x # Violation for LeadingAndTrailingDigits

    while true end # Violation for InfiniteWhileLoop

    returnTypes = Union{Nothing, String, Int32, Int64, Float64} # Violation for TooManyTypesInUnions

    return 1    
end

module lowercase_module # Violation ModuleNameCasing
end 

struct myStruct end # Violation for TypeNamesUpperCamelCase

""", checks;
    filename="dummy.jl", print_ast=true, print_llt=true)
