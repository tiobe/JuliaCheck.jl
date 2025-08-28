module DoNotSetVariablesToNan

include("_common.jl")

using ...SyntaxNodeHelpers

struct Check<:Analysis.Check end
id(::Check) = "do-not-set-variables-to-nan"
severity(::Check) = 3
synopsis(::Check) = "Do not set variables to NaN, NaN16, NaN32 or NaN64"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"=", node -> begin
        if numchildren(node) != 2
            @debug "Assignment with $(numchildren(node)) children instead of 2."
            return
        end
        # Check if right-hand side is an Inf value
        rhs = children(node)[2]
        if extract_special_value(rhs) ∈ SyntaxNodeHelpers.NAN_VALUES
            report_violation(ctxt, this, rhs, synopsis(this))
        end
        
    end)
end

end # module DoNotSetVariablesToNan
