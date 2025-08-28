module GlobalNonConstVariablesShouldHaveTypeAnnotations

include("_common.jl")
using ...Properties: first_child, is_constant, is_global_decl, haschildren

struct Check<:Analysis.Check end
id(::Check) = "global-non-const-variables-should-have-type-annotations"
severity(::Check) = 6
synopsis(::Check) = "Global non-const variables should have type annotations"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> is_global_decl(n) && !is_constant(n), node -> begin
        check(this, ctxt, node)
    end)
end

function check(this::Check, ctxt::AnalysisContext, glob_var::SyntaxNode)
    # This must not be a [const], so it must be [global].
    @assert is_global_decl(glob_var) "Expected a global declaration, got [$(kind(glob_var))]."
    @assert !is_constant(glob_var) "Run this check on non-const global declarations only!"
    if !haschildren(glob_var)
        @debug "Global declaration has no children, skipping check." glob_var
        return nothing
    end
    if kind(glob_var) == K"global" glob_var = first_child(glob_var) end
    if kind(glob_var) == K"="      glob_var = first_child(glob_var) end
    if kind(glob_var) != K"::"
        report_violation(ctxt, this, glob_var,
            "Global non-const variable $glob_var does not have a type annotation."
            )
    end
end

end # module GlobalNonConstVariablesShouldHaveTypeAnnotations
