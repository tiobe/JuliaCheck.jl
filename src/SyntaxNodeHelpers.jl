module SyntaxNodeHelpers

export is_union_decl

import JuliaSyntax: SyntaxNode, @K_str, kind, children, numchildren

"Whether given `node` is a Union declaration."
function is_union_decl(node::SyntaxNode)::Bool
    if kind(node) == K"curly" && numchildren(node) >= 1
        first_child = children(node)[1]
        return kind(first_child) == K"Identifier" && string(first_child) == "Union"
    end
    return false
end

end # module SyntaxNodeHelpers
