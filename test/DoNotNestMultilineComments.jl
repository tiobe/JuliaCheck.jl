# Bad style:
function foo()::Nothing
    #= multiline nesting 0 open
    #= multiline nesting 1 open
    #= multiline nesting 2 open
    #= multiline nesting 3 open
    Don't nest comments!
    =# multiline nesting 3 close
    =# multiline nesting 2 close
    =# multiline nesting 1 close

    This is still a comment.
    =#
    
    #= #= This is a multiline comment (on one line) =# =#

    println("This is code.")
    return nothing
end

# Good style:
function foo()::Nothing
    #=∈
    All your comments can be put here
    on as many lines as you want.
    Try to be concise and accurate.
    ∈=#

    ##=#= Not a multiline comment =#=#

    println("This is code.")
    return nothing
end