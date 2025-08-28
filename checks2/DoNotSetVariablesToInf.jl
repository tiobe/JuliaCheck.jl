module DoNotSetVariablesToInf

using ...SyntaxNodeHelpers

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "do-not-set-variables-to-inf"
severity(::Check) = 3
synopsis(::Check) = "Do not set variables to Inf, Inf16, Inf32 or Inf64"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"=", node -> begin
        if numchildren(node) != 2
            @debug "Assignment with $(numchildren(node)) children instead of 2."
            return
        end
        # Check if right-hand side is an Inf value
        rhs = children(node)[2]
        if extract_special_value(rhs) ∈ SyntaxNodeHelpers.INF_VALUES
            report_violation(ctxt, this, rhs, synopsis(this))
        end

    end)
end

end # module DoNotSetVariablesToInf
