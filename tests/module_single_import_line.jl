module module_single_import_line

module BadStyle

    using LinearAlgebra, Random, Statistics, Test
    using JuliaSyntax: GreenNode, SyntaxNode, children

end # module BadStyle

module GoodStyle

    using LinearAlgebra
    using Random
    using Statistics
    using Test
    using JuliaSyntax: GreenNode, SyntaxNode, children

end # module GoodStyle

end # module_single_import_line
