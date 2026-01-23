module module_single_import_line

module BadStyle
    using .SomeSubmodule
    using .SomeOtherSubmodule

    using LinearAlgebra, Random, Statistics, Test

end # module BadStyle

module ReportOnlyOnceOnUsingOrdering

    using A
    using D
    using C
    using B

end # module ReportOnlyOnceOnIncludeOrdering

module ReportOnlyOnceOnIncludeOrdering

    include("JuliaA.jl")
    include("JuliaD.jl")
    include("JuliaC.jl")
    include("JuliaB.jl")

end # module ReportOnlyOnceOnIncludeOrdering

module StillReportOnAnInterleavedMess

    using E
    using H
    include("JuliaF.jl")
    include("JuliaG.jl")
    using G
    using F
    include("JuliaE.jl")
    include("JuliaH.jl")
    using I, J, K

end # module StillReportOnAnInterleavedMess

module GoodStyle

    using JuliaSyntax: GreenNode, SyntaxNode, children
    using LinearAlgebra
    using Random
    using Statistics
    using Test

end # module GoodStyle

end # module_single_import_line
