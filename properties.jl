is_toplevel(  node::Node) = kind(node) == K"toplevel"
is_module(    node::Node) = kind(node) == K"module"
is_assignment(node::Node) = kind(node) == K"="

function is_op_call(node::Node)
    return  JSx.is_prefix_op_call(node) ||
            is_infix_operator(node)  ||
            JSx.is_postfix_op_call(node)
end
function is_infix_operator(node::Node)
    return JSx.is_infix_op_call(node) ||
           kind(node) in KSet"= == === != !== && || ->"
end

function is_function(node::Node)
    return kind(node) == K"function" ||
           is_assignment(node) && kind(children(node)[1]) == K"call"
end

function opens_scope(node::Node)
    # @debug "{\n" length(nested_modules) length(symbols_table)
    return is_function(node) ||
           kind(head(node)) ∈ [KSet"for while try do let macro generator"]
                                # comprehensions contain a generator
end
function closes_scope(node::Node, parent::Node)
    # @debug "}\n" length(nested_modules) length(symbols_table)
    return kind(head(node)) == K"end" && opens_scope(parent)
end

function closes_module(node::Node, parent::Node)
    return kind(node) == K"end" && kind(parent) == K"module"
end

function get_func_name(node::Node)
    @assert is_function(node) "Not a [function] node!"
    call = find_child_of_kind(K"call", node)
    return if !isnothing(call)
                children(call)[1]
            else
                @debug "No [call] node found for a [function] node:\n" *
                        sprint(show, MIME("text/plain"), node)
                "-function?-"
            end
end
function get_func_arguments(node::Node)
    @assert is_function(node) "Not a [function] node!"
    call = find_child_of_kind(K"call", children(node)[1])
    if isnothing(call)
        @debug "No [call] node found for a [function] node:\n" *
                sprint(show, MIME("text/plain"), node)
        return []
    end
    items_in_function_signature = children(call)
    fun_args = filter(x -> kind(x) == K"Identifier", items_in_function_signature
                     )[2:end]   # discard the function's name (1st identifier in this list)
    if (kind(last(items_in_function_signature)) == K"parameters")
        map(x -> push!(fun_args, children(x)[1]),   # TODO better way to merge lists?
            children(last(items_in_function_signature)))
    end
    return fun_args
end
#= function get_parameters(node::Node)
    @assert kind(node) == K"parameters" "Not a [parameters] node!"
    @assert all(x -> kind(x) == K"=", children(node)) """
        Not all children of a [parameters] node turned out to be [=]:
        $node
        """
    return map(x -> child(x, 1), children(node))
end
=#

get_assignee(node::Node) = children(node)[1]

# TODO make unit tests for this (and thus start having tests)
function find_child_of_kind(node_kind::Kind, node::Node)
    # First, check the node itself
    if kind(node) == node_kind return node end
    # If not, check its direct children
    n = findfirst(x -> kind(x) == node_kind, children(node))
    if !isnothing(n)
        return children(node)[n]
    else
        # If that is also a no, pass the search to those children, one by one,
        # until one returns a matching node. Otherwise, return `nothing`.
        next = iterate(children(node))
        while next !== nothing
            (_, state) = next
            child = children(node)[next]
            grandchild = find_child_of_kind(node_kind, child)
            if !isnothing(grandchild)
                return grandchild
            end
            next = iterate(children(node), state)
        end
        return nothing
    end
end
