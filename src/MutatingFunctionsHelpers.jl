module MutatingFunctionsHelpers

export get_mutated_variables_in_scope

using JuliaSyntax: SyntaxNode, children
using ..Analysis
using ..Properties: is_array_assignment, is_mutating_call, is_broadcasting_assignment, is_field_assignment

"""Returns a set of all variables that are mutated within a given scope.

Finds this out by doing a depth-first search through the function, and picking out all
assignments and call that mutate a variable. Currently, this list is:
* assignments to an array element      (eg. x[1] = 1)
* mutating function calls              (eg. push!(x, 1))
* broadcasting assignments to an array (eg. x .= 1)
* field assignments on a type          (eg. x.field = 1)
"""
function get_mutated_variables_in_scope(ctxt::AnalysisContext, scope_node::SyntaxNode)::Set{String}
    all_mutated_variables = Set{String}()
    visitor_func(n::SyntaxNode)::Nothing = begin
        if is_array_assignment(n)
            mutated_var = string(first(children(n)))
            push!(all_mutated_variables, mutated_var)
        elseif is_mutating_call(n)
            mutated_var = string(children(n)[2])
            push!(all_mutated_variables, mutated_var)
        elseif is_broadcasting_assignment(n)
            mutated_var = string(first(children(n)))
            push!(all_mutated_variables, mutated_var)
        elseif is_field_assignment(n)
            field_assignment = first(children(n))
            mutated_var = string(first(children(field_assignment)))
            push!(all_mutated_variables, mutated_var)
        end
        return nothing
    end
    Analysis.dfs_traversal(ctxt, scope_node, visitor_func)
    return all_mutated_variables
end

end # module MutatingFunctionsHelpers
