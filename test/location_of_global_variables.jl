module module_include_location

module MyBadStylePackage

    using Statistics

    include("SomeSubmodule.jl")
    import .SomeSubmodule

    include("CoreModule.jl")

    function foo()::Nothing
        return nothing
    end

    const MY_GLOB = 42

end # module MyBadStylePackage

const SOME_GLOBAL = 0.7

module MyGoodStylePackage

    using Statistics

    include("SomeOtherSubModule.jl")  # includes should be placed below the import/using list
    import .SomeOtherSubModule

    include("SomeSubmodule.jl")  # except `include` for a submodule
    import .SomeSubmodule

    const MY_GLOB = 42

    function foo()::Nothing
        return nothing
    end

end # module MyGoodStylePackage

end # module module_include_location
