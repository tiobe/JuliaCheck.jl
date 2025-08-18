module TypeNamesUpperCamelCase

include("_common.jl")

using ...Properties: is_upper_camel_case, find_lhs_of_kind

struct Check <: Analysis.Check end
id(::Check) = "type-names-upper-camel-case"
severity(::Check) = 3
synopsis(::Check) = """Type names should be in "UpperCamelCase"."""

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) === K"struct", node -> begin
        identifier = find_lhs_of_kind(K"Identifier", node)
        if identifier !== nothing
            name = string(identifier)
            if ! is_upper_camel_case(name)
                report_violation(ctxt, this, node, "Type names such as '$name' should be written in \"UpperCamelCase\".")
            end
        end
    end)
end

end
