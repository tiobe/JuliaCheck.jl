module implement_unions_as_consts

module BadStyle

    struct MyStruct
        member_x::Union{Nothing, Int64}
        member_y::Union{Nothing, Int64}
    end

    get_member_x(my_struct::MyStruct)::Union{Nothing, Int64} = my_struct.member_x
    get_member_y(my_struct::MyStruct)::Union{Nothing, Int64} = my_struct.member_y
    function set_member_x(my_struct::MyStruct, value::Union{Nothing, Int64})::MyStruct
        return MyStruct(value, my_struct.member_y)
    end
    function set_member_y(my_struct::MyStruct, value::Union{Nothing, Int64})::MyStruct
        return MyStruct(my_struct.member_x, value)
    end

end   # module BadStyle

module GoodStyle

    """ Nullable integer."""
    const MyUnion = Union{Nothing, Int64}

    struct MyStruct
        member_x::MyUnion
        member_y::MyUnion
    end

    get_member_x(my_struct::MyStruct)::MyUnion = my_struct.member_x
    get_member_y(my_struct::MyStruct)::MyUnion = my_struct.member_y
    function set_member_x(my_struct::MyStruct, value::MyUnion)::MyStruct
        return MyStruct(value, my_struct.member_y)
    end
    function set_member_y(my_struct::MyStruct, value::MyUnion)::MyStruct
        return MyStruct(my_struct.member_x, value)
    end

end  # module GoodStyle

end  # module implement_unions_as_consts
