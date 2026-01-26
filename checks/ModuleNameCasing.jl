module ModuleNameCasing

include("_common.jl")
using ...Properties: get_module_name, is_upper_camel_case

struct Check<:Analysis.Check end
Analysis.id(::Check) = "module-name-casing"
Analysis.severity(::Check) = 5
function Analysis.synopsis(::Check)
    return "Package names and module names should be written in UpperCamelCase"
end

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, n -> kind(n) == K"module", node -> begin
        (mod_id_node, module_name) = get_module_name(node)
            if ! is_upper_camel_case(module_name)
                report_violation(ctxt, this, mod_id_node, "Module name '$module_name' should be written in UpperCamelCase.")
            end
    end)
    return nothing
end

end # module ModuleNameCasing

