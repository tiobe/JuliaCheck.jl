module module_single_import_line

module BadStyle
    using .SomeSubmodule
    using .SomeOtherSubmodule

    using LinearAlgebra, Random, Statistics, Test

end # module BadStyle

module ReportOnlyOnceOnUsingOrdering

    using A
    import D
    using C
    import B

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
    using Metrology
    using MLBase # RM-37946: test for case insensitive ordering
    using Test

end # module GoodStyle

module CaseInsensitiveOrderingForIncludes # RM-37946

    include("JuliaA.jl")
    include("JULIAB.jl")
    include("JuliaC.jl")

end # module GoodStyle2

end # module_single_import_line
