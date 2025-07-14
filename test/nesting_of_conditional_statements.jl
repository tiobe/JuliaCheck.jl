function foo()::Nothing
    if A # nesting level 1
        if B # nesting level 2
            if C # nesting level 3
                if D # nesting level 4 is a violation
                    println("This is a violation of the nesting level rule.")
                end
            end
        end
    end

    return nothing
end

function bar()::Nothing
    if A # nesting level 1
        if B # nesting level 2
            if C # nesting level 3
                println("This is almost a violation of the nesting level rule.")
            else
                if D # nesting level 4 is a violation
                    println("This is a violation of the nesting level rule.")
                end
            end
        end
    end

    return nothing
end

function zilch()::Nothing
    if A # nesting level 1
        if B # nesting level 2
            return nothing
        end

        if F # nesting level 1
            return nothing # too
        end
    end

    return nothing
end

const NADA_DE_NADA = map(0:10) do n
    if A
        if B
            if C
                if D
                    nothing
                end
            end
        end
    end
end
