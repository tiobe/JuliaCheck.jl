module TypeNamesUpperCamelCase

include("_common.jl")

using ...Properties: is_upper_camel_case, find_lhs_of_kind

struct Check<:Analysis.Check end
Analysis.id(::Check) = "type-names-upper-camel-case"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Type names should be in \"UpperCamelCase\""

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) ∈ KSet"abstract struct", node -> begin
        identifier = find_lhs_of_kind(K"Identifier", node)
        if ! isnothing(identifier)
            name = string(identifier)
            if ! is_upper_camel_case(name)
                report_violation(ctxt, this, identifier, "Type names such as '$name' should be written in \"UpperCamelCase\".")
            end
        end
    end)
end

end # module TypeNamesUpperCamelCase
