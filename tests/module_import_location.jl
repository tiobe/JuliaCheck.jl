module module_import_location

module MyBadStylePackage

    import Statistics

    function foo()::Nothing
        return nothing
    end

    using Sys # Bad: other code appears before the import list

    include("SomeSubmodule.jl")
    import ..SomeSubmodule

end # module MyBadStylePackage

module MyGoodStylePackage

    using Statistics
    import Sys

    include("SomeSubmodule.jl")
    import ..SomeSubmodule

    function foo()::Nothing
        return nothing
    end

end # module MyGoodStylePackage

end # module module_import_location
