module Utils

using JuliaSyntax: SyntaxNode, GreenNode

display(branch::SyntaxNode) = show(stdout, MIME"text/plain"(), branch)
display(branch::GreenNode)  = show(stdout, MIME"text/plain"(), branch)

to_string(branch::SyntaxNode) = sprint(show, MIME("text/plain"), branch)
to_string(branch::GreenNode)  = sprint(show, MIME("text/plain"), branch)

end
