module FunctionIdentifiersInLowerSnakeCase

using ...Properties: inside, is_lower_snake, is_struct, get_func_name

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "function-identifiers-in-lower-snake-case"
Analysis.severity(::Check) = 8
Analysis.synopsis(::Check) = "Function name should be written in \"lower_snake_case\""

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, n -> kind(n) == K"function", node -> begin
        fname = get_func_name(node)

        if kind(fname.parent) == K"."
            return #RM-37316: do not trigger on extension of a function defined in another module
        end
        _check_function_name(this, ctxt, fname)
    end)
    return nothing
end

function _check_function_name(this::Check, ctxt::AnalysisContext, func_name::SyntaxNode)::Nothing
    @assert kind(func_name) == K"Identifier" "Expected an [Identifier] node, got [$(kind(func_name))]"
    if inside(func_name, is_struct)
        # Inner constructors (functions inside a type definition) must match the
        # type's name, which must follow a different naming convention than
        # functions do, so they are excluded from this check.
        return nothing
    end
    fname = string(func_name)
    if ! is_lower_snake(fname)
        report_violation(ctxt, this, func_name,
            "Function name $fname should be written in lower_snake_case."
            )
    end
    return nothing
end

end # module FunctionIdentifiersInLowerSnakeCase
