module FunctionIdentifiersInLowerSnakeCase

include("_common.jl")

using ...Properties: inside, is_lower_snake, is_struct, get_func_name

struct Check <: Analysis.Check end
id(::Check) = "function-identifiers-in-lower-snake-case"
severity(::Check) = 8
synopsis(::Check) = "Function name should be written in \"lower_snake_case\""

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"function", node -> begin
        fname = get_func_name(node)
        
        checkFunctionName(this, ctxt, fname)
    end)
end

function checkFunctionName(this::Check, ctxt::AnalysisContext, func_name::SyntaxNode)
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
            "Function name $fname should be written in lower_snake_case.", # TODO #36595
            )
    end
end

end # module FunctionIdentifiersInLowerSnakeCase
