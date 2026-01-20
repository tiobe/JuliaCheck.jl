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

function trailing_commentary(x::Int64)::Nothing
    if x > 64
        return nothing
    else
        # Well, what then?
    end
end                # It gets the correct end too, even if there's trailing whitespace and comments.

# Good style
function foo()::String
    return "foo!"
end

function bar()::Nothing
    println("println returns nothing")
    return nothing
end

short_hand() = "just to make sure"
