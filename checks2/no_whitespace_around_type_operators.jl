module NoWhitespaceAroundTypeOperators

include("_common.jl")

using JuliaSyntax: first_byte, last_byte, SyntaxData, GreenNode, children, is_whitespace
using ...Properties: is_toplevel

struct Check <: Analysis.Check end
id(::Check) = "no-whitespace-around-type-operators"
severity(::Check) = 7
synopsis(::Check) = "Do not add whitespace around type operators"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_type_assertion_or_constraint, n -> check(this, ctxt, n))
end

function is_type_assertion_or_constraint(node)
    return kind(node) in KSet":: <: >:"
end

function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    if length(node.children) != 2
        @debug "Expected a node with two children, got [$(length(node.children))]." node
        return
    end
    start = nextind(ctxt.sourcecode, last_byte(node.children[1]))
    last = prevind(ctxt.sourcecode, first_byte(node.children[2]))
    text_between = ctxt.sourcecode[start:last]
    if any(isspace, text_between)
        report_violation(ctxt, this, node, synopsis(this), 
            offsetspan = (start - node.data.position, length(text_between))
            )
    end
end

end # module NoWhitespaceAroundTypeOperators
