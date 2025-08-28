module Analysis

export AnalysisContext, Violation, run_analysis, register_syntaxnode_action, report_violation
export Check, id, synopsis, severity, init
export GreenLeaf, find_greenleaf, kind, sourcetext
export find_syntaxnode_at_position

using JuliaSyntax

import JuliaSyntax: SyntaxNode, GreenNode, Kind, kind, sourcetext, source_location
import InteractiveUtils: subtypes

# Here to keep Properties importable as ..Properties by SymbolTable.
# Mainly to ensure that it's imported in the same way by both
# production code and tests.
using ..Properties
using ..SymbolTable

"The abstract base type for all checks."
abstract type Check end
id(this::Check)::String = error("id() not implemented for this check")
synopsis(this::Check)::String = error("synopsis() not implemented for this check")
severity(this::Check)::Int = error("severity() not implemented for this check")
init(this::Check, ctxt) = error("init() not implemented for this check")

struct Violation
    check::Check
    linepos::Tuple{Int,Int} # The line and column of the violation
    bufferrange::UnitRange{Integer} # The character range in the source code
    msg::String
end

struct GreenLeaf
    sourcefile::SourceFile
    node::GreenNode
    range::UnitRange{Int} # The character range in the source code
end
"Returns the source code for the GreenLeaf."
sourcetext(gl::GreenLeaf)::String = gl.sourcefile.code[gl.range]
"Returns the kind of the GreenNode inside the GreenLeaf."
kind(gl::GreenLeaf) = kind(gl.node)
source_location(gl::GreenLeaf) = source_location(gl.sourcefile, gl.range.start)

struct CheckRegistration
    predicate::Function # A predicate function that determines if the action applies to a SyntaxNode
    action::Function # The action to be performed on SyntaxNode when the predicate applies
end

struct AnalysisContext
    rootNode::SyntaxNode
    greenleaves::Vector{GreenLeaf}
    registrations::Vector{CheckRegistration} # Holds registrations of syntax node actions.
    violations::Vector{Violation}
    symboltable::SymbolTableStruct

    AnalysisContext(node::SyntaxNode, greenLeaves::Vector{GreenLeaf}) = new(node, greenLeaves, CheckRegistration[], Violation[], SymbolTableStruct())
end

"Finds GreenLeaf containing given position."
function find_greenleaf(ctxt::AnalysisContext, pos::Int)::Union{GreenLeaf, Nothing}
    return _find_greenleaf(ctxt.greenleaves, pos)
end

"Performs a binary search to find the GreenLeaf containing given position."
function _find_greenleaf(leaves::Vector{GreenLeaf}, pos::Int)::Union{GreenLeaf, Nothing}
    low = 1
    high = length(leaves)
    while low <= high
        mid_idx = low + (high - low) ÷ 2
        mid_leaf = leaves[mid_idx]
        mid_range = mid_leaf.range

        if pos in mid_range
            return mid_leaf
        elseif pos < mid_range.start
            high = mid_idx - 1
        else # pos > mid_range.stop
            low = mid_idx + 1
        end
    end
    return nothing
end

function _get_green_leaves!(list::Vector{GreenLeaf}, sf::SourceFile, node::GreenNode, pos::Int)
    cs = children(node)
    if cs === nothing
        range = pos:pos+node.span-1
        push!(list, GreenLeaf(sf, node, range))
        return
    end

    p = pos
    for child in cs
        _get_green_leaves!(list, sf, child, p)
        p += child.span
    end
end

function _get_green_leaves(node::SyntaxNode)::Vector{GreenLeaf}
    list::Vector{GreenLeaf} = Vector()
    _get_green_leaves!(list, node.source, node.raw, node.data.position)
    return list
end

"""
    find_syntaxnode_at_position(node::SyntaxNode, pos::Integer)::Union{SyntaxNode, Nothing}

Finds the most specific SyntaxNode that spans the given character position `pos`.
"""
function find_syntaxnode_at_position(node::SyntaxNode, pos::Integer)::Union{SyntaxNode, Nothing}
    # Check if the current node's range contains the position.
    if ! (pos in JuliaSyntax.byte_range(node))
        return nothing
    end

    # Iterate through children to find a more specific node.
    for child in children(node)
        found_child = find_syntaxnode_at_position(child, pos)
        if found_child !== nothing
            return found_child
        end
    end

    # If no child contains the position, this node is the most specific node
    return node
end

"""
    find_syntaxnode_at_position(ctxt::AnalysisContext, pos::Integer)::Union{SyntaxNode, Nothing}

Finds the most specific SyntaxNode that spans the given character position `pos`.
"""
function find_syntaxnode_at_position(ctxt::AnalysisContext, pos::Integer)::Union{SyntaxNode, Nothing}
    return find_syntaxnode_at_position(ctxt.rootNode, pos)
end


"Should be called by checks in their init function to register actions."
function register_syntaxnode_action(ctxt::AnalysisContext, predicate::Function, func::Function)::Nothing
    push!(ctxt.registrations, CheckRegistration(predicate, func))
    return nothing
end

"""
    Reports a violation for a check in the analysis context.

    Use `offsetspan` to specify the range of the violation relative to the node's position.
 """
function report_violation(ctxt::AnalysisContext, check::Check, node::SyntaxNode, msg::String;
    offsetspan::Union{Nothing, Tuple{Int,Int}} = nothing
    )::Nothing
    linepos = JuliaSyntax.source_location(node)
    bufferrange = JuliaSyntax.byte_range(node)

    if offsetspan !== nothing
        bufferrange = range(bufferrange.start + offsetspan[1], length=offsetspan[2])
    end

    push!(ctxt.violations, Violation(check, linepos, bufferrange, msg))
    return nothing
end

function report_violation(ctxt::AnalysisContext, check::Check,
    linepos::Tuple{Int,Int},
    bufferrange::UnitRange{Int},
    msg::String
    )::Nothing
    push!(ctxt.violations, Violation(check, linepos, bufferrange, msg))
    return nothing
end

function _stop_traversal(node::SyntaxNode)::Bool
    if kind(node) == K"quote"
        return true
    elseif kind(node) == K"macrocall" &&
            numchildren(node) >= 1 &&
            string(children(node)[1]) == "@eval"
        return true
    else
        return false
    end
end

function dfs_traversal(ctxt::AnalysisContext, node::SyntaxNode, visitor_func::Function)::Nothing
    # 1. Update the symbol table before running on the node.
    update_symbol_table_on_node_enter!(ctxt.symboltable, node)

    # 2. Process the current node (Pre-order: process before children)
    visitor_func(node)

    if _stop_traversal(node)
        return nothing
    end

    # 3. Recursively visit children
    local children = JuliaSyntax.children(node)
    if children === nothing
        return
    end
    for child_node in children
        dfs_traversal(ctxt, child_node, visitor_func)
    end
    # 4. Update the symbol table when leaving a node.
    #    Needs to be done here, in the DFS - because
    #    a node needs to be processed inside its scope.
    update_symbol_table_on_node_leave!(ctxt.symboltable, node)
    return nothing
end

"Load all check modules in checks2 directory."
function discover_checks()::Nothing
    for file in filter(f -> endswith(f, ".jl"), readdir(joinpath(@__DIR__, "..", "checks2"), join=true))
        try
            include(file)
        catch exception
            @warn "Failed to load check '$(basename(file))':" exception
        end
    end
    return nothing
end

function invoke_checks(ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    visitor = function(n::SyntaxNode)
        for reg in ctxt.registrations
            if reg.predicate(n)
                #println("Invoking action for node type: ", reg.nodeType)
                reg.action(n)
            else
                #println("Not a match: $(reg.nodeType) vs $(kind(n))")
            end
        end
    end

    # TODO: Is the enter and exit on the main level really necessary?
    enter_main_module!(ctxt.symboltable)
    dfs_traversal(ctxt, node, visitor)
    exit_main_module!(ctxt.symboltable)
    return nothing
end


function simple_violation_printer(sourcefile::SourceFile, violations)::Nothing
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
    return nothing
end

function run_analysis(sourcefile::SourceFile, checks::Vector{Check};
    print_ast::Bool = false, 
    print_llt::Bool = false, 
    violationprinter::Function = simple_violation_printer
    )::Nothing

    if length(checks) >= 1
        @debug "Enabled rules:\n" * join(map(id, checks), "\n")
    else 
        throw("No rules to check")
    end

    syntaxNode = JuliaSyntax.parseall(SyntaxNode, sourcefile.code; filename=sourcefile.filename)
    ctxt = AnalysisContext(syntaxNode, _get_green_leaves(syntaxNode))
    for check in checks
        typeof(check)
        init(check, ctxt)
    end

    if print_ast
        println("Showing AST:")
        show(stdout, MIME"text/plain"(), syntaxNode)
    end
    if print_llt
        println("Showing green tree:")
        show(stdout, MIME"text/plain"(), syntaxNode.raw, sourcefile.code)
    end

    invoke_checks(ctxt, syntaxNode)
    violationprinter(sourcefile, ctxt.violations)
    return nothing
end

end # module Analysis
