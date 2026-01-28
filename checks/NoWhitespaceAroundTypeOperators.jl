module NoWhitespaceAroundTypeOperators

using JuliaSyntax: first_byte, last_byte, is_prefix_op_call

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "no-whitespace-around-type-operators"
Analysis.severity(::Check) = 7
Analysis.synopsis(::Check) = "Do not add whitespace around type operators"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, _is_type_assertion_or_constraint, n -> _check(this, ctxt, n))
    return nothing
end

function _is_type_assertion_or_constraint(node)::Bool
    return kind(node) in KSet":: <: >:"
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
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
            range(start; length=length(text_between)),
            "Omit whitespace around this operator"
            )
    end
    return nothing
end

end # module NoWhitespaceAroundTypeOperators
