module module_import_location

module MyBadStylePackage

    import Base

    function foo()::Nothing
        return nothing
    end

    using Statistics # Bad: other code appears before the import list

    include("SomeSubmodule.jl")
    import ..SomeSubmodule

end # module MyBadStylePackage

module MyGoodStylePackage

    import Base
    using Statistics

    include("SomeSubmodule.jl")
    import ..SomeSubmodule

    function foo()::Nothing
        return nothing
    end

end # module MyGoodStylePackage

end # module module_import_location
