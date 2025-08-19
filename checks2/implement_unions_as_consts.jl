module ImplementUnionsAsConsts

include("_common.jl")

using ...Properties: is_assignment, is_constant, is_union_decl

struct Check <: Analysis.Check end
id(::Check) = "implement-unions-as-consts"
severity(::Check) = 3
synopsis(::Check) = "Implement Unions as const."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_union_decl, node -> begin
        checkUnion(this, ctxt, node)
    end)
end

function checkUnion(this::Check, ctxt::AnalysisContext, union::SyntaxNode)
    @assert is_union_decl(union) "Expected a Union declaration, got $(kind(union))"
    if is_assignment(union.parent) && is_constant(union.parent.parent)
        # This seems to be a Union type declaration
        if union == children(union.parent)[2]
            # Confirmed. In this case, there is nothing to report.
            return nothing
        end
    end
    report_violation(ctxt, this, union, 
        "Declare this Union as a const type before using it.")
end

end # module ImplementUnionsAsConsts

