module AvoidGlobalVariables

using ...Properties: is_global_decl, is_constant, find_lhs_of_kind
using ...SyntaxNodeHelpers
using ...SymbolTable

include("_common.jl")

struct Check<:Analysis.Check
    already_reported::Set{SyntaxNode}
    Check() = new(Set{SyntaxNode}())
end
Analysis.id(::Check) = "avoid-global-variables"
Analysis.severity(::Check) = 3
Analysis.synopsis(::Check) = "Avoid global variables when possible"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_global_decl, node -> begin
        id = find_lhs_of_kind(K"Identifier", node)
        if isnothing(id)
            return
        end
        if any(n -> kind(n) == K"const", ancestors(id))
            # Const global is OK
            return
        end
        if !is_global(ctxt.symboltable, id)
            return
        end
        if id ∈ this.already_reported
            return
        end
        push!(this.already_reported, id)

        report_violation(ctxt, this, id, synopsis(this))
        return nothing
    end)
    return nothing
end

end # module AvoidGlobalVariables
