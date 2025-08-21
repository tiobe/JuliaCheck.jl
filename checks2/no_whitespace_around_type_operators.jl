module NoWhitespaceAroundTypeOperators

include("_common.jl")

using JuliaSyntax: first_byte, last_byte, is_prefix_call, is_prefix_op_call
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
    code = node.source.code
    if is_prefix_op_call(node)
        start = node.position
        last = first_byte(node.children[1])
    else 
        if length(node.children) != 2
            @warn "Expected a node with two children, got [$(length(node.children))]." node
            return
        end
        start = nextind(code, last_byte(node.children[1]))
        last = prevind(code, first_byte(node.children[2]))
    end
    text_between = code[start:last]
    if any(isspace, text_between)
        linepos = source_location(node.source, start)
        report_violation(ctxt, this, 
            linepos,
            range(start, length=length(text_between)),
            "Omit whitespace around this operator" 
            )
    end
end

end # module NoWhitespaceAroundTypeOperators
