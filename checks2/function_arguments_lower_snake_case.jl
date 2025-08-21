module FunctionArgumentsLowerSnakeCase

using ...Properties: find_lhs_of_kind, is_lower_snake, get_func_name, get_func_arguments, haschildren

include("_common.jl")

struct Check <: Analysis.Check end
id(::Check) = "function-arguments-lower-snake-case"
severity(::Check) = 7
synopsis(::Check) = "Function arguments must be written in \"lower_snake_case\""

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"function", node -> begin
        fname = get_func_name(node)
        fname_str = string(fname)
        for arg in get_func_arguments(node)
            if kind(arg) == K"parameters"
                if ! haschildren(arg)
                    @debug "Odd case of childless [parameters] node $(JS.source_location(node)):" node
                    return nothing
                end
                # The last argument in the list is itself a list, of named arguments.
                for arg in children(arg)
                    checkArgument(this, ctxt, fname_str, arg)
                end
            else
                checkArgument(this, ctxt, fname_str, arg)
            end
        end
    end)
end

function checkArgument(this::Check, ctxt::AnalysisContext, f_name::AbstractString, f_arg::SyntaxNode)
    if kind(f_arg) == K"::"
        f_arg = numchildren(f_arg) == 1 ? nothing : children(f_arg)[1]
    end
    if f_arg !== nothing
        f_arg = find_lhs_of_kind(K"Identifier", f_arg)
    end
    if isnothing(f_arg)
        # Nothing to check; maybe a ::Val or ::Type, or perhaps a semicolon
        # followed by nothing at all (nasty)
        return nothing
    end
    arg_name = string(f_arg)
    if ! is_lower_snake(arg_name)
        report_violation(ctxt, this, f_arg, 
            "Argument '$arg_name' of function '$f_name' must be written in \"lower_snake_case\"." # TODO #36595
            )
    end
end

end # module FunctionArgumentsInLowerSnakeCase

