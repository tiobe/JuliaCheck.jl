import JuliaCheck


"""
Runs JuliaCheck for a given rule on the testfile of that rule.
The testfile shares the basename with the check, but is in the /test/ directory instead of the /checks/ directory.
The rule shares the same name as the specified file, which is expected to be a check with corresponding rule id
(Same as filename, with '-' instead of '_').
This is used for debugging purposes in VSCode (to enable pressing F5 to debug when editing a check).
"""
function Debug(filename::String)
    if basename(dirname(filename)) === "checks"
        testfile = realpath(joinpath(dirname(filename), "..", "test", basename(filename)))
        rulename = replace(splitext(basename(filename))[1], "_" => "-")
        JuliaCheck.main(["--verbose", "--enable", rulename, "--", testfile])
    else 
        include(filename)
    end
end

Debug(ARGS[1]) # This will be set by the launch.json configuration in VSCode
