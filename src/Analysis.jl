module Analysis

export AnalysisContext, Violation, run_analysis, register_syntaxnode_action, report_violation
export Check, id, synopsis, severity, init

using JuliaSyntax

import JuliaSyntax: SyntaxNode, GreenNode, Kind, kind, sourcetext
import InteractiveUtils: subtypes

"The abstract base type for all checks."
abstract type Check end
id(this::Check)::String = error("id() not implemented for this check")
synopsis(this::Check)::String = error("synopsis() not implemented for this check")
severity(this::Check)::Int = error("severity() not implemented for this check")
init(this::Check, ctxt) = error("init() not implemented for this check")

struct Violation
    check::Check
    linepos::Tuple{Int,Int} # The line and column of the violation
    bufferrange::UnitRange{Int} # The range in the source code buffer
    msg::String
end


struct CheckRegistration
    predicate::Function # A predicate function that determines if the action applies to a SyntaxNode
    action::Function # The action to be performed on SyntaxNode when the predicate applies
end

struct AnalysisContext
    sourcecode::String
    registrations::Vector{CheckRegistration} # Holds registrations of syntax node actions.
    violations::Vector{Violation}

    AnalysisContext(sourcecode::String) = new(sourcecode, CheckRegistration[], Violation[])
end

"Should be called by checks in their init function to register actions."
function register_syntaxnode_action(ctxt::AnalysisContext, predicate::Function, func::Function)
    push!(ctxt.registrations, CheckRegistration(predicate, func))
end

"""
    Reports a violation for a check in the analysis context.
    
    Use `offsetspan` to specify the range of the violation relative to the node's position.
 """
function report_violation(ctxt::AnalysisContext, check::Check, node::SyntaxNode, msg::String; 
    offsetspan::Union{Nothing, Tuple{Int,Int}} = nothing
    )
    linepos = JuliaSyntax.source_location(node)
    bufferrange = JuliaSyntax.byte_range(node)

    if offsetspan !== nothing
        bufferrange = range(bufferrange.start + offsetspan[1], length=offsetspan[2])
    end

    push!(ctxt.violations, Violation(check, linepos, bufferrange, msg))
end

function report_violation(ctxt::AnalysisContext, check::Check, 
    linepos::Tuple{Int,Int}, 
    bufferrange::UnitRange{Int},
    msg::String
    )
    push!(ctxt.violations, Violation(check, linepos, bufferrange, msg))
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
        for reg in ctxt.registrations
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


function simple_violation_printer(violations)
    if length(violations) == 0
        println("No violations found.")
    else 
        println("Found $(length(violations)) violations:")
        idx = 1
        for v in violations
            println("$(idx). Check: $(id(v.check)), Line/col: $(v.linepos), Severity: $(severity(v.check)), Message: $(v.msg)")
            idx += 1
        end
    end    
end

function run_analysis(text::String, checks::Vector{Check};
    filename::String = nothing,
    print_ast::Bool = false, 
    print_llt::Bool = false, 
    violationprinter::Function = simple_violation_printer
    )

    #println("($(length(checks))) checks to run: $(string(checks))")
    ctxt = AnalysisContext(text)
    for check in checks
        init(check, ctxt)
    end

    syntaxNode = JuliaSyntax.parseall(SyntaxNode, text; filename=filename)
    if print_ast
        println("Showing AST:")
        show(stdout, MIME"text/plain"(), syntaxNode)
    end
    if print_llt
        println("Showing green tree:")
        show(stdout, MIME"text/plain"(), syntaxNode.raw, text)
    end

    invoke_checks(ctxt, syntaxNode)

    violationprinter(ctxt.violations)

end

end # module Analysis
