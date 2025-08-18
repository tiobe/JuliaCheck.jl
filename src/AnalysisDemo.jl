# This file demonstrates the proposed Check and AnalysisContext types that are more in line with Roslyn analysis
# Checks implementing the Check type are in check2 directory
using InteractiveUtils

include("Analysis.jl")
include("LosslessTrees.jl")
include("Properties.jl");
include("SyntaxNodeHelpers.jl")

# Load all check modules in checks2
for file in filter(f -> endswith(f, ".jl"), readdir(joinpath(@__DIR__, "..", "checks2"), join=true))
    try
        include(file)
    catch exception
        @warn "Failed to load check '$(basename(file))':" exception
    end
end

using .Analysis

global enabledChecks = subtypes(Check)

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

""", enabledChecks)
