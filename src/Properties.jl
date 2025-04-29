module Properties

import JuliaSyntax: Kind, SyntaxNode, @K_str, @KSet_str, children, head, kind,
    untokenize, JuliaSyntax as JS

export opens_scope, closes_module, closes_scope, find_child_of_kind,
    is_assignment, is_function, is_infix_operator, is_literal, is_module,
    is_operator, is_toplevel, get_assignee, get_func_arguments, get_func_name,
    report_violation

function report_violation(node::JS.SyntaxNode, problem::String, rule::String)
    line, column = JS.source_location(node)
    printstyled("\n'$(JS.filename(node))', line $line, column $(column+1):\n";
                underline=true)
    JS.highlight(stdout, node; note=problem, notecolor=:yellow,
                               context_lines_after=0, context_lines_before=0)
    printstyled("\n$rule\n"; color=:cyan)
    @debug "\n" * to_string(node)
end

is_toplevel(  node::SyntaxNode) = kind(node) == K"toplevel"
is_module(    node::SyntaxNode) = kind(node) == K"module"
is_assignment(node::SyntaxNode) = kind(node) == K"="
is_literal(   node::SyntaxNode) = kind(node) in KSet"Float Integer"
is_function(  node::SyntaxNode) = kind(node) == K"function"

function is_operator(node::SyntaxNode)
    return  JS.is_prefix_op_call(node) ||
            is_infix_operator(node)  ||
            JS.is_postfix_op_call(node)
end
function is_infix_operator(node::SyntaxNode)
    A = JS.is_infix_op_call(node)
    B = JS.is_operator(node)
    C = kind(node) in KSet"= == === != !== && || ->"
    return A || B || C
end


function opens_scope(node::SyntaxNode)
    return is_function(node) ||
           kind(node) ∈ [KSet"for while try do let macro generator"]
                                # comprehensions contain a generator
end
function closes_scope(node::SyntaxNode)
    return kind(node) == K"end" && opens_scope(node.parent)
end
function closes_module(node::SyntaxNode)
    return kind(node) == K"end" && is_module(node.parent)
end


function get_func_name(node::SyntaxNode)::String
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

function get_func_arguments(node::SyntaxNode)
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
#= function get_parameters(node::SyntaxNode)
    @assert kind(node) == K"parameters" "Not a [parameters] node!"
    @assert all(x -> kind(x) == K"=", children(node)) """
        Not all children of a [parameters] node turned out to be [=]:
        $node
        """
    return map(x -> child(x, 1), children(node))
end
=#

get_assignee(node::SyntaxNode) = children(node)[1]

# TODO make unit tests for this (and thus start having tests)
function find_child_of_kind(node_kind::Kind, node::SyntaxNode)
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


end
