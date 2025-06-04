module module_include_location

module MyBadStylePackage

    include("CoreModule.jl")  # Bad: includes should be placed below the import/using list

    using Statistics

    include("SomeSubmodule.jl")
    import .SomeSubmodule

    function foo()::Nothing
        return nothing
    end

end # module MyBadStylePackage

module MyGoodStylePackage

    using Statistics

    include("SomeOtherSubModule.jl")  # includes should be placed below the import/using list
    import .SomeOtherSubModule

    include("SomeSubmodule.jl")  # except `include` for a submodule
    import .SomeSubmodule

    function foo()::Nothing
        return nothing
    end

end # module MyGoodStylePackage

end # module module_include_location
