module DebugCheck

import JuliaCheck

"""
Runs JuliaCheck on the specified file, which is expected to be a check with corresponding rule id
(Same as filename, with '-' instead of '_').
This is used for debugging purposes in VSCode (to enable pressing F5 to debug when editing a check).
"""
function Debug(filename::String)
    rulename = replace(splitext(basename(filename))[1], "_" => "-")
    JuliaCheck.main(["--verbose", "--enable", rulename, "--", filename])
end

Debug(ARGS[1]) # This will be set by the launch.json configuration in VSCode

end