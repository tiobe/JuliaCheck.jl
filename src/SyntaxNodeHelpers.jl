module SyntaxNodeHelpers

export ancestors, is_scope_construct

using JuliaSyntax: SyntaxNode, kind

import JuliaSyntax: @KSet_str

"Returns list of ancestors for given node, excluding self, ordered by increasing distance."
function ancestors(node::SyntaxNode)::Vector{SyntaxNode}
    list=Vector{SyntaxNode}()
    n = node.parent
    while n !== nothing
        push!(list, n)
        n = n.parent
    end
    return list
end

"""
Whether this node introduces a new scope.
See https://docs.julialang.org/en/v1/manual/variables-and-scoping/
"""
function is_scope_construct(node::SyntaxNode)::Bool
    return kind(node) in KSet"module baremodule struct for while try macro function"
end

end # module SyntaxNodeHelpers
