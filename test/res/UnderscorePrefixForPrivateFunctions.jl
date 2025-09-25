module IAmAnExportTestModule

export i_am_exported_without_underscore, _i_am_exported_with_underscore, warblgarbl

function i_am_exported_without_underscore()::Bool
    return false
end

function i_am_not_exported_without_underscore()::Bool
    return false
end

function _i_am_exported_with_underscore()::Bool
    return false
end

function _i_am_not_exported_with_underscore()::Bool
    return false
end

end 