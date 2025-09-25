module TypeHelpers

export get_variable_type_from_node, is_different_type, TypeSpecifier

using JuliaSyntax: children, is_infix_op_call, is_leaf, is_literal, kind, numchildren, SyntaxNode, @K_str
using ..Properties: get_call_name_from_call_node, is_call

#=
Nothing represents "unknown" type. Type change should check only
one "known" type to another "known" type. As for now, only the
types that are returned as literals, and are flagged as such in
JuliaSyntax.jl/src/julia/kinds.jl.

Currently, possible literals in JuliaSyntax are:

"Bool"
"Integer"
"BinInt"
"HexInt"
"OctInt"
"Float"
"Float32"
"String"
"Char"
"CmdString"

All of these are returned as kinds, and are flagged by the is_literal function. 
=#      
TypeSpecifier = Union{String, Nothing}

function is_different_type(type_1::TypeSpecifier, type_2::TypeSpecifier)::Bool
    if isnothing(type_1) || isnothing(type_2)
        return false
    end
    return type_1 != type_2
end

"""
Tries to find the type of the associated variable from a node.

For now, this only covers assignments of the form 
a = /something/.
"""
function get_variable_type_from_node(node::SyntaxNode)::TypeSpecifier
    if kind(node) == K"="
        return _get_type_from_assignment(node)
    end
    return nothing
end

function _get_type_from_assignment(assignment_node::SyntaxNode)::TypeSpecifier
    rhs = children(assignment_node)[2]
    if is_literal(rhs)
        # No further parsing is necessary on JuliaSyntax literals.
        # Here, the kind can be returned as a string.
        return string(kind(rhs))
    elseif is_call(rhs)
        return _get_type_of_call_return(rhs)
    end
    return nothing
end

"""
Resolves expected return types of calls.

For now, only covers explicit type casting to string.

If we want to attempt more explicit resolution, this should be done by
a call comparable to this:

Base.return_types(getfield(Base, Symbol(function_name)))

This would be a start with being able to handle at least arbitrary functions
within the base libraries, and which types they return. Dependent on which
overload of a function is used, of course. Would still require a lot of work.
"""

function _get_type_of_call_return(call_node::SyntaxNode)::TypeSpecifier
    call_type = get_call_name_from_call_node(call_node)
    if lowercase(call_type) == "string"
        return "String"
    end
    return nothing
end

end # module TypeHelpers
