module Analysis

export AnalysisContext, Violation, run_analysis, register_syntaxnode_action, report_violation
export Check, id, synopsis, severity, init

using JuliaSyntax

import JuliaSyntax: SyntaxNode, GreenNode, Kind, kind, sourcetext
import InteractiveUtils: subtypes

" The abstract base type for all checks."
abstract type Check end
id(this::Check) = error("id() not implemented for this check")
synopsis(this::Check) = error("synopsis() not implemented for this check")
severity(this::Check) = error("severity() not implemented for this check")
init(this::Check, ctxt) = error("init() not implemented for this check")

struct Violation
    check::Check
    line::Int
    column::Int
    msg::String
end

struct CheckRegistration
    predicate::Function # A predicate function that determines if the action applies to a SyntaxNode
    action::Function # The action to be performed on SyntaxNode when the predicate applies
end

struct AnalysisContext
    sourcecode::String
    syntaxNodeActions::Vector{CheckRegistration}
    violations::Vector{Violation}

    AnalysisContext(sourcecode::String) = new(sourcecode, CheckRegistration[], Violation[])
end

"Should be called by checks in their init function to register actions."
function register_syntaxnode_action(ctxt::AnalysisContext, predicate::Function, func::Function)
    push!(ctxt.syntaxNodeActions, CheckRegistration(predicate, func))
end

"Reports a violation for a check in the analysis context."
function report_violation(ctxt::AnalysisContext, check::Check, node::SyntaxNode, msg::String)
    line, column = JuliaSyntax.source_location(node)
    push!(ctxt.violations, Violation(check, line, column, msg))
end


function dfs_traversal(node::SyntaxNode, visitor_func::Function)
    # 1. Process the current node (Pre-order: process before children)
    visitor_func(node)

    # 2. Recursively visit children
    local children = JuliaSyntax.children(node)
    if children === nothing
        return
    end
    for child_node in children
        dfs_traversal(child_node, visitor_func)
    end
end

"Load all check modules in checks2 directory."
function load_all_checks2()
    for file in filter(f -> endswith(f, ".jl"), readdir(joinpath(@__DIR__, "..", "checks2"), join=true))
        try
            include(file)
        catch exception
            @warn "Failed to load check '$(basename(file))':" exception
        end
    end
end

function invoke_checks(ctxt::AnalysisContext, node::SyntaxNode)
    visitor = function(n)
        for reg in ctxt.syntaxNodeActions
            if reg.predicate(n)
                #println("Invoking action for node type: ", reg.nodeType)
                reg.action(n)
            else
                #println("Not a match: $(reg.nodeType) vs $(kind(n))")
            end
        end
    end
    dfs_traversal(node, visitor)
end

function run_analysis(text::String, checks::Vector{Check};
    print_ast::Bool = false, print_llt::Bool = false)

    println("Checks to run ($(length(checks))): " * string(checks))
    ctxt = AnalysisContext(text)
    for check in checks
        init(check, ctxt)
    end

    syntaxNode = JuliaSyntax.parseall(SyntaxNode, text)
    greenNode = JuliaSyntax.parseall(GreenNode, text)
    if print_llt
        println("Showing green tree:")
        show(stdout, MIME"text/plain"(), greenNode, text)
    end

    #print("Printing node\n")
    #print(syntaxNode)

    invoke_checks(ctxt, syntaxNode)

    if length(ctxt.violations) == 0
        println("No violations found.")
    else 
        println("Found $(length(ctxt.violations)) violations:")
        for v in ctxt.violations
            println("Check: $(id(v.check)), Line: $(v.line), Column: $(v.column), Severity: $(severity(v.check)), Message: $(v.msg)")
        end
    end

end

end # module Analysis
