

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
"""
This docstring is long, in order to provide lots oḟ context
and explanation for the function.

It does things, then reports on the things we did.
If no things were done, the report will be empty.

As docstrings are not comments, this is okay and no violation is reported.
"""
function doThings()::String
    return """
    I have done all the things,
    including writing this long string
    which I am reporting now.
    This should not become a multiline comment.
    There are lots of interesting findings here,
    from doing the thing
    """
end
