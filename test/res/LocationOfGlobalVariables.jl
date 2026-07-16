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

module AnotherBadStylePackage

    using Statistics

    """
    This function is documented, and should still be treated as something that prevents
    the const MY_GLOB to be considered 'at the top of the file'.
    """
    function foo()::Nothing
        return nothing
    end

    const MY_GLOB = 42

end # module MyBadStylePackage

module MyGoodStylePackage

    using Statistics

    include("SomeOtherSubModule.jl")  # includes should be placed below the import/using list
    import .SomeOtherSubModule

    include("SomeSubmodule.jl")  # except `include` for a submodule
    import .SomeSubmodule

    # a comment is no problem

    """
    a long form comment is no problem either
    """

    const MY_GLOB = 42
    
    """
    and neither is a docstring right in front of a global
    """
    const YES_ANOTHER_ONE = 43

    const AND_ANOTHER = 44

    function foo()::Nothing
        return nothing
    end

end # module MyGoodStylePackage

module AnotherGoodStylePackage

    using Statistics

    # So, technically, this is another assignment, and as such should _not_ trigger
    # the rule on both this assignment and the assignment after it.
    string_assignment = """yes, this is a string assignment!"""

    const YET_ANOTHER_THINGIE = 5

end # module AnotherGoodStylePackage

end # module module_include_location
