module ImplementUnionsAsConsts

using ...Properties: is_assignment, is_constant, is_union_decl

include("_common.jl")

struct Check<:Analysis.Check end
Analysis.id(::Check) = "implement-unions-as-consts"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Implement Unions as const"

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_union_decl, node -> begin
        _check_union(this, ctxt, node)
    end)
end

function _check_union(this::Check, ctxt::AnalysisContext, union::SyntaxNode)::Nothing
    @assert is_union_decl(union) "Expected a Union declaration, got $(kind(union))"
    if is_assignment(union.parent) && is_constant(union.parent.parent)
        # This seems to be a Union type declaration
        if union == children(union.parent)[2]
            # Confirmed. In this case, there is nothing to report.
            return nothing
        end
    end
    report_violation(ctxt, this, union, "Declare this Union as a const type before using it.")
    return nothing
end

end # module ImplementUnionsAsConsts

