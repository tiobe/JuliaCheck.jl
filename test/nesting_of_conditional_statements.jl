function foo()::Nothing
    if A # nesting level 1
        while B # nesting level 2
            for c in C # nesting level 3
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
        while B # nesting level 2
            if C # nesting level 3
                println("This is almost a violation of the nesting level rule.")
            else
                for d in D # nesting level 4 is a violation
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

        if C # nesting level 2
            return nothing # too
        end
    end

    return nothing
end

const NADA_DE_NADA = map(0:10) do n
    while A # nesting level 1
        if B    # nesting level 2
            for c in C  # nesting level 3
                d = try D() # nesting level 4 is a violation
                    catch
                        nothing
                    end
            end
        end
    end
end
