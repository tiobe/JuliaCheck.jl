module NestingOfConditionalStatements

include("_common.jl")

using ...Properties: is_flow_cntrl, is_stop_point

struct Check <: Analysis.Check end
id(::Check) = "nesting-of-conditional-statements"
severity(::Check) = 4
synopsis(::Check) = "Avoid deep nesting of conditional statements."

const MAX_ALLOWED_NESTING_LEVELS = 3
const USER_MSG = "This conditional expression is too deeply nested (deeper than $MAX_ALLOWED_NESTING_LEVELS levels)."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_flow_cntrl, n -> check(this, ctxt, n))
end

function check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    @assert is_flow_cntrl(node) "Expected a flow control node, got [$(kind(node))]."

    # Count the nesting level of conditional statements
    if conditional_nesting_level(node) > MAX_ALLOWED_NESTING_LEVELS
        length_of_keyword = length(string(kind(node)))
        report_violation(ctxt, this, node, USER_MSG; offsetspan=(0, length_of_keyword))
    end
end

function conditional_nesting_level(node::SyntaxNode)::Int
    level = 0
    while !isnothing(node) && !is_stop_point(node)
        if is_flow_cntrl(node)
            level += 1
        end
        node = node.parent
    end
    return level
end

end # module NestingOfConditionalStatements
