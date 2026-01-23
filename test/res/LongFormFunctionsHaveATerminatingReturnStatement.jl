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

function if_with_elseif_and_else_missing_if(x)::Int
    if x == 1
        println("some statement")
        println("missing return")
    elseif x == 2
        return 2
    else
        return 3
    end
end  # Bad: missing return for `if x == 1`

function if_with_elseif_and_else_missing_elseif(x)::Int
    if x == 1
        return 1
    elseif x == 2
        println("some statement")
        println("missing return")
    else
        return 3
    end
end # Bad: missing return for `elseif x == 2`

function if_with_elseif_and_else_missing_else(x)::Int
    if x == 1
        return 1
    elseif x == 2
        return 2
    else
        println("some statement")
        println("missing return")
    end
end # Bad: missing return for `else`

# Good style
function foo()::String
    return "foo!"
end

function bar()::Nothing
    println("println returns nothing")
    return nothing
end

short_hand() = "just to make sure"

function if_with_else(x)::Int
    if x == 1
        return 1
    else
        return 2
    end
end

function if_with_elseif_and_else(x)::Int
    if x == 1
        return 1
    elseif x >= 2
        if x % 2 == 0
            return 2
        else
            return 3
        end
    else
        return 4
    end
end
