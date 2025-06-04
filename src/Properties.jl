module Properties

import JuliaSyntax: Kind, GreenNode, SyntaxNode, SourceFile, @K_str, @KSet_str,
    children, head, kind, span, untokenize, JuliaSyntax as JS

export MAX_LINE_LENGTH, opens_scope, closes_module, closes_scope, haschildren,
    increase_counters, is_abstract, is_assignment, is_constant, is_function,
    is_infix_operator, is_loop, is_literal, is_lower_snake, is_module,
    is_operator, is_struct, is_toplevel, is_union_decl, is_upper_camel_case,
    expr_depth, expr_size, find_first_of_kind, get_assignee, get_func_arguments,
    get_func_body, get_func_name, get_struct_members, get_struct_name,
    lines_count, report_violation, reset_counters, SF, source_index,
    to_pascal_case


## Global definitions
global SF::SourceFile
SOURCE_INDEX = 0
SOURCE_LINE = 0
const MAX_LINE_LENGTH = 92


## Functions

function report_violation(node::SyntaxNode;
                          severity::Int, user_msg::String,
                          summary::String, rule_id::String)
    line, column = JS.source_location(node)
    printstyled("\n$(JS.filename(node))($line, $(column)):\n";
                underline=true)
    JS.highlight(stdout, node; note=user_msg, notecolor=:yellow,
                               context_lines_after=0, context_lines_before=0)
    _report_common(severity, rule_id, summary)
end
function report_violation(; index::Int, len::Int, line::Int, col::Int,
                            severity::Int, user_msg::String,
                            summary::String, rule_id::String)
    printstyled("\n$(JS.filename(SF))($line, $col):\n";
                underline=true)
    JS.highlight(stdout, SF, index:index+len-1;
                 note=user_msg, notecolor=:yellow,
                 context_lines_after=0, context_lines_before=0)
    _report_common(severity, rule_id, summary)
end
function _report_common(severity::Int, rule_id::String, summary::String)
    printstyled("\n$summary"; color=:cyan)
    printstyled("\nRule:"; underline=true)
    printstyled(" $rule_id. ")
    printstyled("Severity:"; underline=true)
    printstyled(" $severity\n")
end


function haschildren(node)
    subnodes = children(node)
    return (! isnothing(subnodes)) && length(subnodes) > 0
end

function is_lower_snake(s::AbstractString)
    return isnothing(match(r"[[:upper:]]", s))
end
function is_upper_camel_case(s::AbstractString)
    m = match(r"([[:upper:]][[:lower:][:digit:]]+)+", s)
    return !isnothing(m) && length(m.match) == length(s)
end


is_toplevel(  node::SyntaxNode) = kind(node) == K"toplevel"
is_module(    node::SyntaxNode) = kind(node) == K"module"
is_assignment(node::SyntaxNode) = kind(node) == K"="
is_literal(   node::SyntaxNode) = kind(node) in KSet"Float Integer"
is_function(  node::SyntaxNode) = kind(node) == K"function"
is_struct(    node::SyntaxNode) = kind(node) == K"struct"
is_abstract(  node::SyntaxNode) = kind(node) == K"abstract"
is_loop(      node::SyntaxNode) = kind(node) in KSet"while for"
is_constant(  node::SyntaxNode) = kind(node) == K"const"

function is_union_decl(node::SyntaxNode)
    if kind(node) == K"curly" && haschildren(node)
        first_child = children(node)[1]
        return kind(first_child) == K"Identifier" && string(first_child) == "Union"
    end
    return false
end

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


function inside(node::SyntaxNode, predicate::Function)::Bool
    return !isnothing(node.parent) && (     # if we reach the top, return false
        predicate(node.parent) ||           # test the node's parent
        inside(node.parent, predicate)      # if false, keep going up
    )
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


function get_func_name(node::SyntaxNode)
    @assert is_function(node) "Expected a [function] node, got [$(kind(node))]."
    fname = find_first_of_kind(K"Identifier", node)
    if isnothing(fname)
        @debug "Unprocessed corner case:" node
        return nothing
    end
    if  kind(fname.parent) == K"."  # In this case, the 1st child is a module name
        fname = children(fname.parent)[2]
    end
    if kind(fname) == K"quote"  # Overloading an operator, which comes next
        fname = children(fname)[1]
    end
    return fname
end

function get_func_arguments(node::SyntaxNode)
    @assert is_function(node) "Expected a [function] node, got [$(kind(node))]."
    call = find_first_of_kind(K"call", children(node)[1])
    if isnothing(call)
        @debug "No [call] node found for a [function] node:\n" node
        return []
    end
    return children(call)[2:end]    # discard the function's name (1st identifier in this list)
end

function get_func_body(node::SyntaxNode)
    @assert is_function(node) "Expected a [function] node, got [$(kind(node))]."
    if ! haschildren(node) || length(children(node)) < 2
        @debug "Strange function node. Cannot return its body." node
        return nothing
    end
    return children(node)[2]
end


function get_assignee(node::SyntaxNode)
    @assert kind(node) == K"=" "Expected a [=] node, got [$(kind(node))]."
    children(node)[1]   # FIXME
end


function get_struct_name(node::SyntaxNode)
    @assert kind(node) == K"struct" "Expected a [struct] node, got [$(kind(node))]."
    return find_first_of_kind(K"Identifier", node)
end

function get_struct_members(node::SyntaxNode)
    @assert kind(node) == K"struct" "Expected a [struct] node, got [$(kind(node))]."
    if length(children(node)) < 2 || kind(children(node)[2]) != K"block"
        @debug "[block] not found where expected." node
        return nothing
    end
    # Return the children of that [block] node:
    return children(children(node)[2])
end


function find_first_of_kind(node_kind::Kind, node::SyntaxNode)
    child = node
    while kind(child) != node_kind && haschildren(child)
        child = children(child)[1]
    end
    return kind(child) == node_kind ? child : nothing
end

expr_depth(node::SyntaxNode) = (! haschildren(node)) ? 1 :
                                    (1 + maximum(expr_depth.(children(node))))
expr_size(node::SyntaxNode) = (! haschildren(node)) ? 1 :
                                    (1 + sum(expr_size.(children(node))))


reset_counters() = global SOURCE_INDEX = 1; global SOURCE_LINE = 1
function increase_counters(node::GreenNode)
    if kind(node) in KSet"NewlineWs String"
        global SOURCE_LINE += line_breaks(node)     # with the current SOURCE_INDEX
    end
    global SOURCE_INDEX += span(node)
end
function sourcetext(node::GreenNode)
    start = SOURCE_INDEX
    ending = SOURCE_INDEX + span(node) - 1
    return JS.sourcetext(SF)[start : ending]
end
line_breaks(node::GreenNode) = count(r"\n", sourcetext(node))
source_index() = SOURCE_INDEX
lines_count() = SOURCE_LINE


function to_pascal_case(s::String)
    result::String = ""
    got_dash::Bool = true
    for c in s
        if c == '-'
            got_dash = true
        else
            result *= got_dash ? uppercase(c) : c
            got_dash = false
        end
    end
end

end
