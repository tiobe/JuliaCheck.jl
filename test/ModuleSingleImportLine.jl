module module_single_import_line

module BadStyle
    using .SomeSubmodule
    using .SomeOtherSubmodule

    using LinearAlgebra, Random, Statistics, Test

end # module BadStyle

module GoodStyle

    using JuliaSyntax: GreenNode, SyntaxNode, children
    using LinearAlgebra
    using Random
    using Statistics
    using Test

end # module GoodStyle

end # module_single_import_line
