some_number::Float64 = 1
const global some_other_number = 42
another_number = 42506

function foo()
    global yet_another_number = 7.0
    local_var = 9
    return nothing
end

SOME_NUMBER::Float64
global const SOME_OTHER_NUMBER::Int = 42
const N1 = const N2 = 3.14159

function bar()
    global YET_ANOTHER_NUMBER = 7.0
    return nothing
end

some_function(:AnIdentifier;
            path="somepath", # RM-37330: prevent false positive for keyword argument
            file=exeFile)

CASES = (
    (m = 1, n = 1) => (x, y) -> x, y # RM-37330: prevent false positive for named tuples
)

# RM-37725: should not trigger on field assignments
ExternalModule.EXTERNAL_GLOBAL.timeout = 3600
