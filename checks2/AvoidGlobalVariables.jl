module AvoidGlobalVariables

using ...Properties: is_global_decl, is_constant, find_lhs_of_kind
using ...SyntaxNodeHelpers

include("_common.jl")

struct Check<:Analysis.Check
    already_reported::Set{SyntaxNode}
    Check() = new(Set{SyntaxNode}())
end
id(::Check) = "avoid-global-variables"
severity(::Check) = 3
synopsis(::Check) = "Avoid global variables when possible"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_global_decl, node -> begin
        id = find_lhs_of_kind(K"Identifier", node)
        if isnothing(id)
            return
        end
        if any(n -> kind(n) == K"const", ancestors(id))
            # Const global is OK
            return
        end
        if id ∈ this.already_reported
            return
        end
        push!(this.already_reported, id)

        report_violation(ctxt, this, id, synopsis(this))
        return nothing
    end)
end

end # module AvoidGlobalVariables
