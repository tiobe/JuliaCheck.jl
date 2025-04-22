using JuliaSyntax: is_whitespace

function space_around_infix_operators(op_call::Node, parent::Node, sf::SourceFile)
    parts = children(op_call)
    op_pos = findfirst(JSx.is_operator, parts)
    if op_pos == 1
        # Infix operator in 1st position and it has children: we let it run
        # on, and it will eventually get to those children.
        if ! JSx.haschildren(parts[1])
            @error "Infix operator is expression's 1st child but it doesn't have any children itself."
            @error "\n" * sprint(show, MIME("text/plain"), op_call)
        end
        return nothing
    end
    # In the general case, we want (only) one space on either side of the operator,
    # while in the exceptional cases (type operators TODO ?and within brackets?),
    # we want the reverse condition: no spaces on neither side of the operator.
    exceptional = kind(head(op_call)) == K"::"  # Exceptions
    meets_criteria = _get_criteria(exceptional)
    (lhs, rhs) = get_op_surrounds(op_call, op_pos)
    if !( meets_criteria(lhs) && meets_criteria(rhs) )
        # TODO s/span/char_range/
        offset = sum(JSx.span.(parts[1:op_pos-1]))  # chars between expression' start and operator
        report_violation(
            LOC + offset, sf, "Bad format around operator",
            "There should be " * (
                exceptional ? "no spaces around that operator."
                    : "exactly one space on either side of that operator."
            )
        )
        @debug "\n" * sprint(show, MIME("text/plain"), op_call)
    end
end

function _get_criteria(is_exception::Bool)
    return is_exception ? (x -> !is_whitespace(x)) :
                          (x -> is_whitespace(x) && (kind(x) == K"NewlineWs" ||
                                                     JSx.span(x) == 1))
end

# FIXME to use SyntaxNode properly, and move to Properties.jl
function get_op_surrounds(op_call::Node, nothing::Nothing)
    @error "No operator found among the children of the given node:\n"
    @error display(op_call)
end
function get_op_surrounds(op_call::Node, op_pos::Int)
    parts = children(op_call)
    (lhs, rhs) = (parts[op_pos-1], parts[op_pos+1])
    if !is_whitespace(rhs)
        while kind(rhs) == K"call"
            # Look at the 1st child of the RHS expression for that whitespace
            rhs = children(rhs)[1]
        end
    end
    return (lhs, rhs)
end
