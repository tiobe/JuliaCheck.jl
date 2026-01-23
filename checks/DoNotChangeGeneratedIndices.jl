module DoNotChangeGeneratedIndices

using ...Properties: first_child, get_assignee, get_iteration_parts,
                    is_assignment, is_flow_cntrl, is_range

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "do-not-change-generated-indices"
Analysis.severity(::Check) = 5
Analysis.synopsis(::Check) = "Do not change generated indices"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, n -> kind(n) == K"for", n -> _check_for_loop(this, ctxt, n))
    return nothing
end

function _check_for_loop(this::Check, ctxt::AnalysisContext, for_loop::SyntaxNode)::Nothing
    loop_var, iter_expr = get_iteration_parts(for_loop)
    if isnothing(loop_var) || isnothing(iter_expr)
        return nothing
    end
    var_name = _loop_var_to_string(loop_var)
    if is_range(iter_expr) || (
        kind(iter_expr) == K"call" &&
        kind(first_child(iter_expr)) == K"Identifier" &&
        string(first_child(iter_expr)) ∈ ["eachindex", "enumerate", "axes"]
        )
        # Look into the loop's body to see if `loop_var` is modified.
        @assert numchildren(for_loop) == 2 &&
                kind(children(for_loop)[2]) == K"block" "An empty loop or what? $for_loop"
        body = children(for_loop)[2]
        _frisk_for_modification(this, ctxt, body, var_name)
    end
    return nothing
end

function _loop_var_to_string(var::SyntaxNode)::String
    x = var
    if kind(x) == K"tuple" x = first_child(x) end
    if kind(x) == K"Identifier" return string(x) end
    @debug "Can't find identifier in loop variable" var
    return ""
end

function _frisk_for_modification(this::Check, ctxt::AnalysisContext, body::SyntaxNode, var_name::String)::Nothing
    for expr in children(body)
        if is_assignment(expr)
            lhs_node, lhs_str = get_assignee(expr)
            if lhs_str == var_name
                report_violation(ctxt, this, lhs_node, synopsis(this))
            end

        elseif is_flow_cntrl(expr)
            next_victim = findfirst(x -> kind(x) == K"block", children(expr))
            if ! isnothing(next_victim)
                _frisk_for_modification(this, ctxt, children(expr)[next_victim], var_name)
            end
        end
    end
    return nothing
end

end # module DoNotChangeGeneratedIndices

