module NestedModulesOk

module SubModuleA

module SubSubModuleA

end # SubSubModuleA

function somewhere_hidden()::Nothing
    return nothing
end

end # SubModuleA
module SubModuleB

end # SubModuleB

function something_or_nothing()::Nothing
    return nothing
end

end # NestedModulesOk

