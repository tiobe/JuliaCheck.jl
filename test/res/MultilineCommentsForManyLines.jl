

# Bad style
# start of comment

# This is an example of a multiline
# comment. This part would be ignored by the compiler.

# You can elaborately describe your code here and define its functions.
a = true
# blabla
# I have lots more to say
# This is an example of a multiline
# comment. This part would be ignored by the compiler.
# You can elaborately describe your code here and define its functions.
x = 3
# end of comment # OK: not too many lines
# Second comment
y = 1
# Good style
#= start of comment

This is an example of a multiline
comment. This part would be ignored by the compiler.

You can elaborately describe your code here and define its functions.

end of comment =#
#= another multiline x1 =#
#= another multiline x2 =#
#= another multiline x3 =#
#= another multiline x4 =#
