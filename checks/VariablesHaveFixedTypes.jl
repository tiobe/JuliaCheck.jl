module VariablesHaveFixedTypes

using JuliaSyntax: is_leaf
using ...SymbolTable: get_initial_type_of_node, get_var_from_assignment, type_has_changed_from_init
using ...TypeFunctions: get_type, is_different_type
using ...Properties: is_assignment, NullableNode

include("_common.jl")

#=
To improve performance and understandability of code, it helps to keep types static.

There are multiple ways to try and check types. Unfortunately, JuliaCheck is relatively
limited in its typing settings; it doesn't go beyond various basic types. Something like
eval calls or usage of Cthulhu (the Julia type inference package: see
https://github.com/JuliaDebug/Cthulhu.jl) would be far too expensive or require us to
check during runtime.

The current state of this rule is very basic. Further type checks are going to be
implemented as they are found. The handling of types within Julia is very extensive
and doing this completely would be a _lot_ of specific cases.
=#

struct Check<:Analysis.Check end
id(::Check) = "variables-have-fixed-types"
severity(::Check) = 3
synopsis(::Check) = "Types of variables should not change."

function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_assignment, n -> check(this, ctxt, n))
    return nothing
end

function check(this::Check, ctxt::AnalysisContext, assignment_node::SyntaxNode)::Nothing
    if type_has_changed_from_init(ctxt.symboltable, assignment_node)
        assigned_variable = get_var_from_assignment(assignment_node)
        initial_type = get_initial_type_of_node(ctxt.symboltable, assignment_node)
        current_type = get_type(assignment_node)
        report_violation(ctxt, this, assignment_node,
          "Variable '$assigned_variable' has changed type (from $initial_type to $current_type).")
    end
    return nothing
end

end # end AvoidContainersWithAbstractTypes
