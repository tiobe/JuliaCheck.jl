module IAmAnExportTestModule

export i_am_exported_without_underscore, _i_am_exported_with_underscore


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

export second_export_is_also_flagged, _even_if_underscored

function second_export_is_also_flagged()::Bool
    return false
end

function _even_if_underscored()::Bool
    return false
end

end 