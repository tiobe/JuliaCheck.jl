module LongFormFunctionsHaveATerminatingReturnStatement

include("_common.jl")

using ...Properties: inside, is_struct, get_func_name, get_func_body, haschildren
using ...WhitespaceHelpers: normalized_green_child_range

struct Check<:Analysis.Check end
Analysis.id(::Check) = "long-form-functions-have-a-terminating-return-statement"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Long form functions should end with an explicit return statement"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, n -> kind(n) == K"function", node -> begin
        body = get_func_body(node)
        if ! isnothing(body)
            _check(this, ctxt, body)
        end
    end)
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, func_body::SyntaxNode)::Nothing
    @assert kind(func_body.parent) == K"function" "Expected the body of a [function], got $(kind(func_body))"
    fname = get_func_name(func_body.parent)
    if isnothing(fname) fname = "<invalid>" end
    if kind(func_body) != K"block" || inside(func_body, is_struct)
        # It is either a short-form function or an inner constructor.
        return
    end
    if !_ends_with_return(func_body)
        parent = func_body.parent
        green_children = children(parent.raw)
        end_range = normalized_green_child_range(parent, lastindex(green_children))
        report_violation(ctxt, this, end_range, synopsis(this))
    end
    return nothing
end

function _ends_with_return(node::SyntaxNode)::Bool
    if kind(node) == K"block"
        if ! haschildren(node)
            # Empty block. Odd, but happens. Assuming it should contain "return nothing"
            return false
        end
        return _ends_with_return(children(node)[end])
    elseif kind(node) ∈ KSet"if elseif"
        # The first child of the [if] is the condition,
        # the rest are either [block] or [elseif]
        return all(_ends_with_return, children(node)[2:end])
    elseif kind(node) == K"return"
        return true
    else
        return false
    end
end

end # module LongFormFunctionsHaveATerminatingReturnStatement
