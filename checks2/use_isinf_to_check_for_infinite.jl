module UseIsinfToCheckForInfinite

include("_common.jl")

using ...Properties: is_eq_neq_comparison
using ...SyntaxNodeHelpers

struct Check <: Analysis.Check end
id(::Check) = "use-isinf-to-check-for-infinite"
severity(::Check) = 3
synopsis(::Check) = "Use isinf to check for infinite values"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_eq_neq_comparison, node -> begin
        apply_to_operands(node, n -> checkExpr(this, ctxt, n))
    end)
end

function checkExpr(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    inf_type = extract_inf_type(node)
    if inf_type !== nothing
        report_violation(ctxt, this, node, synopsis(this))
    end
end

function extract_inf_type(node::SyntaxNode)::Union{String, Nothing}
    sign = ""
    if kind(node) == K"call" && numchildren(node) > 1
        first, second = children(node)[1:2]
        if kind(first) == K"Identifier" && string(first) ∈ ("-", "+")
            if string(first) == "-" 
                sign = "-" 
            end
            node = second
        end
    end

    if kind(node) == K"." && length(children(node)) >= 2
        # For qualified names like Base.Inf, return just the Inf part
        node = last(children(node))
    end

    if kind(node) == K"Identifier"
        value = string(node)
        if value ∈ ("Inf", "Inf16", "Inf32", "Inf64")
            return sign * value
        end
    end

    return nothing
end


end # module UseIsinfToCheckForInfinite
