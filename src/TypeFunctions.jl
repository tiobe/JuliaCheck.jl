module TypeFunctions

export get_type, is_different_type, TypeSpecifier

using JuliaSyntax: children, is_infix_op_call, is_leaf, is_literal, kind, SyntaxNode, @K_str
using ..Properties: get_call_name_from_call_node, is_call

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
    return type_1 != type_2
end

function get_type(node::SyntaxNode)::TypeSpecifier
    if kind(node) == K"="
        return _get_type_from_assignment(node)
    end
    return nothing
end

function _get_type_from_assignment(assignment_node::SyntaxNode)::TypeSpecifier
    rhs = children(assignment_node)[2]

    # TODO: parsing and processing of custom types
    if is_literal(rhs)
        return string(kind(rhs))
    elseif is_infix_op_call(rhs)
        return _get_infix_type(rhs)
    elseif is_call(rhs)
        return _get_call_type(rhs)
    end
    return nothing
end

function _get_call_type(call_node::SyntaxNode)::TypeSpecifier
    call_type = get_call_name_from_call_node(call_node)
    if call_type == "string"
        return "String"
    end
    return nothing
end

function _get_infix_type(infix_node::SyntaxNode)::TypeSpecifier
    stringified_infix = string(children(infix_node)[2])
    if stringified_infix == "/"
        return "Float"
    elseif stringified_infix == "^"
        return "Integer"
    end
    return nothing
end

end # module TypeFunctions
