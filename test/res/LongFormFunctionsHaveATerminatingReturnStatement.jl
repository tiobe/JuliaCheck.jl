# Bad style
function void()::Nothing
    nothing
end

function bar()::Nothing
    println("println returns nothing")
end

function with_if(x)
    if x == 0
        return 0
    else
        println(x)
    end
end

function lengthy_function_end()::Nothing
    tuple = (
        a=1,
        b=2,
        c=3,
        d=4,
        e=5
    )
end

# Good style
function foo()::String
    return "foo!"
end

function bar()::Nothing
    println("println returns nothing")
    return nothing
end

short_hand() = "just to make sure"
