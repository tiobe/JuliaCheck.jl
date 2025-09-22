module TypeFunctions

export get_type, TypeSpecifier

using JuliaSyntax: children, kind, SyntaxNode, @K_str

# TODO: Is it really necessary to define our own type handling here?
#       Wish there was some other way of doing this.

# TODO: I think we want to keep the possibility of arbitrary types open.
#       Mainly because we may still be able to find some type changes,
#       even on arbitrary user-specified types.
#       Nothing represents "unknown" type. Type change should check only
#       one "known" type to another "known" type.
TypeSpecifier = Union{String, Nothing}

function is_different_type(type_1::TypeSpecifier, type_2::TypeSpecifier)::Bool
    if isnothing(type_1) || isnothing(type_2)
        return false
    end
    return type_1 == type_2
end

function get_type(node::SyntaxNode)::TypeSpecifier
    if kind(node) == K"="
        return _get_type_from_assignment(node)
    end
    return nothing
end

function _get_type_from_assignment(assignment_node::SyntaxNode)::String
    rhs = children(assignment_node)[2]
    type_string = kind(rhs)
    return type_string
end

end # module TypeFunctions
