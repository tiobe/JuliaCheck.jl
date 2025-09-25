module ModuleInAFileWithNoTrailingNewline

is_newline_ok() = false

function worry_about_absent_newline()::Union{String, Nothing}
    return is_newline_ok() ? nothing : "so worried"
end

end # ModuleInAFileWithNoTrailingNewline