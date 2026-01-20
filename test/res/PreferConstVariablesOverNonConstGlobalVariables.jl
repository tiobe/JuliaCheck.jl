some_number::Float64 = 1
const global some_other_number = 42

function foo()
    global yet_another_number = 7.0 # OK: 'global const' is not allowed in function scope
end

SOME_NUMBER::Float64
global const SOME_OTHER_NUMBER::Int = 42
const N1 = const N2 = 3.14159

CAPS_NUMBER::Int6 = 12

function bar()
    global YET_ANOTHER_NUMBER = 7.0 # OK: 'global const' is not allowed in function scope
end

some_function(:AnIdentifier;
            path="somepath", # RM-37336: prevent false positive for keyword argument
            file=exeFile)

const CASES = (
    (m = 1, n = 1) => (x, y) -> x, y # RM-37336: prevent false positive for named tuples
)
# RM-37723: Enum values are OK
@enum MyEnum::Int64 begin
    VAL1 = 128
    VAL2 = 42
    VAL3 = 0
end

# RM-37724: Do statement creates an anonymous function: so vars inside are not global
map(1:10) do x
    mult = 2
    y = mult * x
end
