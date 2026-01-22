some_number::Float64 = 1 # Bad
const global some_other_number = 42 # Bad
another_number, another_number2 = 42506, 512 # Bad: two violations expected

function foo()
    global another_number = 512 # Good: already reported on declaration above
    global another_number2, fresh_number = 7.0, 8.0 # Bad: one violation expected for fresh_number
    global abc # Good: not an assignment
    local_var = 9 # Good: local variable
    return nothing
end

SOME_NUMBER::Float64 # Good
global const SOME_OTHER_NUMBER::Int = 42 # Good
const N1 = const N2 = 3.14159  # Good

function bar()
    global YET_ANOTHER_NUMBER = 7.0 # Good
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

# RM-37326: do not report on assignment to index `dict[]`
const dict = Dict() # Bad: `dict` should be upper case
dict["a"] = "b" # Good: `dict` is not declared here

# RM-37326, note 7: do not report on same global variable twice
some_number, another_number, yet_another_number = 3, 1, 1 # Bad: yet_another_number
