# This file demonstrates the proposed Check and AnalysisContext types that are more in line with Roslyn analysis
# Checks implementing the Check type are in check2 directory
using InteractiveUtils

include("Analysis.jl")

# Load all check modules in checks2
for file in filter(f -> endswith(f, ".jl"), readdir(joinpath(@__DIR__, "..", "checks2"), join=true))
    try
        include(file)
    catch x
        @warn "Failed to load '$file':" x
    end
end

using .Analysis

global enabledChecks = subtypes(Check)

run_analysis("""
TEST = .5; 

function test(x)
    println("Hello World")
    INSIDE = .25 + x

    while true
    end
    return 1    
end
""", enabledChecks)
