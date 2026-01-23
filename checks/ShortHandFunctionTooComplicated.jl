module ShortHandFunctionTooComplicated

include("_common.jl")
using JuliaSyntax: sourcetext
using ...Properties: MAX_LINE_LENGTH, expr_depth, expr_size, get_func_name, get_func_body

struct Check<:Analysis.Check end
Analysis.id(::Check) = "short-hand-function-too-complicated"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Short-hand notation with concise functions"

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"function", func -> begin
        body = get_func_body(func)
        if !isnothing(body) && kind(body) != K"block"
            _check(this, ctxt, func, body)
        end
    end)
end

function _check(this::Check, ctxt::AnalysisContext, func::SyntaxNode, body::SyntaxNode)
    report() = report_violation(ctxt, this, body,
        "Function '$(get_func_name(func))' is too complex for the shorthand notation; use keyword 'function'."
    )

    line_len = length(sourcetext(func))
    if line_len > MAX_LINE_LENGTH
        report()
    elseif line_len > round(Int, 0.9 * MAX_LINE_LENGTH)
        # The line doesn't exceed the hard length limit, but it's long enough
        # to inspect the "size" of the function definition expression: if the
        # depth is higher than a given limit, or the full size (total number
        # of nodes in the tree) exceeds another limit, we report it, too.
        if expr_depth(body) > 4 || expr_size(body) > 10
            report()
        end
    end
    return nothing
end

end # module ShortHandFunctionTooComplicated
