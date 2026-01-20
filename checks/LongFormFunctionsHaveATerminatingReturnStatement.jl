module LongFormFunctionsHaveATerminatingReturnStatement

include("_common.jl")

using ...Properties: inside, is_struct, get_func_name, get_func_body, haschildren
using ...WhitespaceHelpers: normalized_green_child_range

struct Check<:Analysis.Check end
id(::Check) = "long-form-functions-have-a-terminating-return-statement"
severity(::Check) = 3
synopsis(::Check) = "Long form functions should end with an explicit return statement"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"function", node -> begin
        body = get_func_body(node)
        if body !== nothing
            checkFuncBody(this, ctxt, body)
        end
    end)
end

function checkFuncBody(this::Check, ctxt::AnalysisContext, func_body::SyntaxNode)::Nothing
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
    if ! haschildren(node)
        # Empty block. Odd, but happens. Assuming it should contain "return nothing"
        return false
    end
    last_expr = children(node)[end]
    return if kind(last_expr) == K"if"
        # Each branch of the 'if' is a [block] (the first child is not a branch,
        # but the condition)
        all(_ends_with_return, children(last_expr)[2:end])
    else
        kind(last_expr) == K"return"
    end
end

end # module LongFormFunctionsHaveATerminatingReturnStatement
