module GoodTopLevelModule
include("Properties.jl"); import .Properties

    bad_function() = false

function good_function()
    return true
end
    module BadStyle
        import Statistics

        export bar, foo

        foo()::Nothing = nothing
        bar()::String = "the bar is open " *
                "and closes at 10"
    end # module BadStyle

module GoodStyle
    import Statistics

    include("SomeOtherSubModule.jl")
    using .SomeOtherSubModule

    include("SomeSubmodule.jl")
    using .SomeSubmodule

module BadNestedModule
                    module WayOffModule

                    end
end

    module GoodNestedModule

    module BadDoubleNestedModule

    end

    end

    export foo
    export bar

    foo()::Nothing = nothing
    bar()::String = "the bar is open"

end # module GoodStyle

end # module GoodTopLevelModule
