# Bad style:
character = Char(0)
while true
    # Three possible paths for an iteration
    character = read(stdin, Char)

    if isletter(character)
        break
    end

    if isdigit(character)
        break
    end
end

# Reason to exit the loop is lost, find out again
if isletter(character)
    println("Letter")
else
    println("Digit")
end

# Good style:
character = Char(0)
entered_letter = false
entered_digit= false

while !(entered_letter || entered_digit)
    # One possible path for an iteration
    character = read(stdin, Char)
    entered_letter = isletter(character)
    entered_digit  = isdigit(character)
end

if entered_letter # Reason of exit stored for re-use here
    println("Letter")
else
    println("Digit")
end
