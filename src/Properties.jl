module Properties

import JuliaSyntax: Kind, GreenNode, SyntaxNode, SourceFile, @K_str, @KSet_str,
    head, is_dotted, is_leaf, kind, numchildren, sourcetext, span, untokenize, JuliaSyntax as JS

export AnyTree, NullableNode, EOL, MAX_LINE_LENGTH,

    children, closes_module, closes_scope, expr_depth, expr_size,

    fake_green_node, find_lhs_of_kind, first_child,

    get_assignee, get_call_name_from_call_node, get_flattened_fn_arg_nodes,
    get_func_arguments, get_func_body, get_func_name,
    get_imported_pkg, get_iteration_parts, get_module_name, get_number,
    get_string_arg, get_string_fn_args, get_struct_members, get_struct_name,
    get_var_from_assignment,

    haschildren, increase_counters, is_abstract, is_array_assignment, is_array_indx, is_assignment,
    is_broadcasting_assignment, is_constant, is_dot, is_eq_neq_comparison, is_eval_call, is_export,
    is_fat_snake_case, is_field_assignment, is_flow_cntrl, is_function, is_global_decl,
    is_import, is_include, is_infix_operator, is_literal_number, is_loop, is_lower_snake,
    is_module, is_mutating_call, is_operator, is_range, is_separator, is_stop_point,
    is_struct, is_toplevel, is_type_op, is_union_decl, is_upper_camel_case,

    lines_count, opens_scope,
    source_column, source_index, source_text


## Types
const AnyTree = Union{SyntaxNode, GreenNode}
const NullableString = Union{String, Nothing}
const NullableNode = Union{AnyTree, Nothing}
const NodeAndString = Tuple{AnyTree, NullableString}


## Global definitions
const MAX_LINE_LENGTH = 92
const EOL = (Sys.iswindows() ? "\n\r" : "\n")

## Functions

function is_lower_snake(s::AbstractString)::Bool
    return isnothing(match(r"[[:upper:]]", s))
end
function is_upper_camel_case(s::AbstractString)::Bool
    m = match(r"([[:upper:]][[:lower:][:digit:]]+)+", s)
    return !isnothing(m) && length(m.match) == length(s)
end
function is_fat_snake_case(s::AbstractString)::Bool
    m = match(r"[[:upper:]_[:digit:]]+", s)
    return !isnothing(m) && length(m.match) == length(s)
end


is_toplevel(  node::AnyTree)::Bool = kind(node) == K"toplevel"
is_module(    node::AnyTree)::Bool = kind(node) == K"module"
is_assignment(node::AnyTree)::Bool = kind(node) == K"="
is_dot(       node::AnyTree)::Bool = kind(node) == K"."
is_function(  node::AnyTree)::Bool = kind(node) == K"function"
is_struct(    node::AnyTree)::Bool = kind(node) == K"struct"
is_abstract(  node::AnyTree)::Bool = kind(node) == K"abstract"
is_array_indx(node::AnyTree)::Bool = kind(node) == K"ref"
is_vect(      node::AnyTree)::Bool = kind(node) == K"vect"
is_call(      node::AnyTree)::Bool = kind(node) == K"call"

is_loop(          node::AnyTree)::Bool = kind(node) in KSet"while for"
is_separator(     node::AnyTree)::Bool = kind(node) in KSet", ;"
is_flow_cntrl(    node::AnyTree)::Bool = kind(node) in KSet"if for while try"
is_literal_number(node::AnyTree)::Bool = kind(node) in KSet"Float Integer"

is_broadcasting_assignment(n::SyntaxNode)::Bool = is_assignment(n) && is_dotted(n)
is_field_assignment(       n::SyntaxNode)::Bool = is_assignment(n) && is_dot(first(children(n)))
is_array_assignment(       n::SyntaxNode)::Bool = is_array_indx(n) && is_assignment(n.parent) && is_first_child(n)

# When searching for a parent node of a certain kind, we stop at these nodes:
is_stop_point(node::AnyTree)::Bool =
    kind(node) ∈ KSet"function module do let toplevel macro"

function is_eval_call(node::AnyTree)::Bool
    return kind(node) == K"macrocall" &&
            haschildren(node) &&
            string(children(node)[1]) == "@eval"
end

function is_mod_toplevel(node::AnyTree)::Bool
    return is_toplevel(node) ||
            (kind(node) == K"block" && is_module(node.parent))
end
function is_global_decl(node::AnyTree)::Bool
    return kind(node) ∈ KSet"global const" ||
            # An assignment or base declaration at the (module's) top-level
            # declares a global variable
            (kind(node) ∈ KSet"= ::" && is_mod_toplevel(node.parent))
end
function is_constant(node::AnyTree)::Bool
    return kind(node) == K"const" ||
           (kind(node) == K"global" && haschildren(node) &&
            kind(children(node)[1]) == K"const")
end

function is_union_decl(node::SyntaxNode)::Bool
    if kind(node) == K"curly" && haschildren(node)
        first_child = children(node)[1]
        return kind(first_child) == K"Identifier" && string(first_child) == "Union"
    end
    return false
end

function is_operator(node::AnyTree)::Bool
    return  JS.is_prefix_op_call(node) ||
            is_infix_operator(node)  ||
            JS.is_postfix_op_call(node)
end
function is_infix_operator(node::AnyTree)::Bool
    return JS.is_infix_op_call(node) || JS.is_operator(node)
end

is_type_op(node::AnyTree)::Bool = kind(node) in KSet":: <: >:"

function is_eq_neq_comparison(node::AnyTree)::Bool
    if kind(node) == K"call" && numchildren(node) == 3
        infix_op = children(node)[2]
        return string(infix_op) ∈ ["==", "===", "≡", "!=", "≠", "!==", "≢"]
    end
    return false
end

function is_range(node::SyntaxNode)::Bool
    if kind(node) == K"call" && numchildren(node) >= 2
        kids = children(node)
        return (
            (kind(kids[1]) == K"Identifier" && string(kids[1]) == "range")
            ||
            (kind(kids[2]) == K"Identifier" && string(kids[2]) == ":")
           )
    end
    return false
end

function is_include(node::AnyTree)::Bool
    if kind(node) == K"call" && haschildren(node)
        id = children(node)[1]
        return kind(id) == K"Identifier" && string(id) == "include"
    end
    return false
end
is_import(node::AnyTree)::Bool = kind(node) in KSet"import using" || is_include(node)
is_export(node::AnyTree)::Bool = kind(node) == K"export"


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

"""
Return the node carrying the function's name.
"""
function get_func_name(node::SyntaxNode)::NullableNode
    @assert is_function(node) "Expected a [function] node, got [$(kind(node))]."
    fname = find_lhs_of_kind(K"Identifier", node)
    if isnothing(fname)
        # We give it one more chance to find the function's name: it will return
        # the name of the operator being redefined, or `nothing`.
        return _is_exception_op_redef(children(node)[1])
    end
    if kind(fname.parent) == K"."  # In this case, the 1st child is a module name
        fname = children(fname.parent)[2]
    end
    if kind(fname) == K"quote"  # Overloading an operator, which comes next
        fname = children(fname)[1]
    end
    return fname
end

function _is_exception_op_redef(node::SyntaxNode)::NullableNode
    if kind(node) == K"call"
        fname = children(node)[1]
        if kind(fname) ∈ KSet"$ & :"
            return fname

        elseif kind(fname) == K"quote"
            fname = children(fname)[1]
            if kind(fname) == K"::" return fname end
        end
    end
    return nothing
end

"""
Return a list of nodes representing the arguments of a function.
"""
function get_func_arguments(node::SyntaxNode)::Vector{SyntaxNode}
    @assert is_function(node) "Expected a [function] node, got [$(kind(node))]."
    call = find_lhs_of_kind(K"call", children(node)[1])
    if isnothing(call)
        # Probably a function "stub", which declares a function name but no methods.
        return []
    end
    # This returns all the arguments without any further processing.
    # As such, this may contain:
    # - only positional arguments (direct children)
    # - only keyword arguments    (grandchildren, children of a parameters node)
    # - both                      (combination of children and parameters->grandchildren)
    return children(call)[2:end]    # discard the function's name (1st identifier in this list)
end

function get_func_body(node::SyntaxNode)::NullableNode
    @assert is_function(node) "Expected a [function] node, got [$(kind(node))]."
    if ! haschildren(node) || length(children(node)) < 2
        # Probably a function "stub", which declares a function name but no methods.
        return nothing
    end
    return children(node)[2]
end


function get_assignee(node::SyntaxNode)::NodeAndString
    @assert kind(node) == K"=" "Expected a [=] node, got [$(kind(node))]."
    assignee = find_lhs_of_kind(K"Identifier", node)
    # FIXME In case of field access (`my_struct.some_field = value`), this may
    # not be what we want. Perhaps other cases as well?
    # Yes, also in redefinition of operators like `&`, `$` or `:`
    if isnothing(assignee)
        @debug "No identifier found in assignment $(JS.source_location(node))" node
        throw("No identifier found in assignment!")
    end
    return (assignee, string(assignee))
end


function get_struct_name(node::SyntaxNode)::NullableNode
    @assert kind(node) == K"struct" "Expected a [struct] node, got [$(kind(node))]."
    return find_lhs_of_kind(K"Identifier", node)
end

function get_struct_members(node::SyntaxNode)::Vector{SyntaxNode}
    @assert kind(node) == K"struct" "Expected a [struct] node, got [$(kind(node))]."
    if length(children(node)) < 2 || kind(children(node)[2]) != K"block"
        @debug "[block] not found where expected $(JS.source_location(node))." node
        return []
    end
    # Return the children of that [block] node:
    return children(children(node)[2])
end

function get_module_name(node::SyntaxNode)::NodeAndString
    @assert kind(node) == K"module" "Expected a [module] node, got [$(kind(node))]."
    @assert haschildren(node) "An empty module with no name? That can't be valid!"
    id_node = children(node)[1]
    @assert kind(id_node) == K"Identifier" """
        The first child of a [module] node is not its identifier!
    """
    return (id_node, string(id_node))
end

"""
    get_imported_pkg(node)

Return the first identifier of an imported package.

Given an `import`, `using` or `include` node, it returns the first `Identifier`
node found. Actually, it returns a tuple with that node and its textual
representation, which would be:
  * In case of an `include("path/to/Package.jl")`, it would be `Package`.
  * In case of an `import` or `using` with a `..SubModule`, the text returned by
    this function would be `SubModule`.

If there are multiple packages being imported/used, only the first one is returned.
"""
function get_imported_pkg(node::SyntaxNode)::String
    @assert is_import(node) "Expected a package import declaration, got [$(kind(node))]."
    @assert haschildren(node) "How can an [import] or [using] have nothing behind?"
    if is_include(node)
        pkg = _extract_included_file(node)
        if isnothing(pkg)
            @debug "No file name found in an [include] node $(JS.source_location(node))" node
            return ""
        end
        str = string(pkg)
        if startswith(str, '"') && endswith(str, ".jl\"")
            str = basename(str[2:end-4])
        else
            @debug "File name of submodule is not double-quotted and/or does not end with '.jl'! $(JS.source_location(node))" str
        end
    else
        pkg = children(node)[1]
        if kind(pkg) == K":" || # importing/using items from a package
           kind(pkg) == K"as"   # import with an alias
            pkg = children(pkg)[1]
        end
        @assert kind(pkg) == K"importpath"
        pkg = last(children(pkg))
        str = string(pkg)
    end
    return str
end

function _extract_included_file(included::SyntaxNode)::NullableNode
    file = children(included)[2]
    if kind(file) == K"string" return first_child(file)

    elseif kind(file) == K"call"
        ch1 = first_child(file)
        if kind(ch1) == K"Identifier" && string(ch1) == "joinpath"
            # Return the last string given to `joinpath` (the actual string is
            # the first child of that last node)
            return first_child(last(children(file)))
        end
    end
    @debug "Can't parse an 'include' $(JS.source_location(included)):" included
    return nothing
end


haschildren(node::AnyTree)::Bool = numchildren(node) > 0
children(node::AnyTree)::Vector{AnyTree} = isnothing(node.children) ?
                                                AnyTree[] : node.children
first_child(node::AnyTree)::NullableNode = haschildren(node) ?
                                                children(node)[1] : nothing
is_first_child(node::AnyTree)::Bool = node === first(children(node.parent))

"""
Return the first left-hand side node of the given kind, going down the left-most
sub-tree in each level from the given node.
"""
function find_lhs_of_kind(node_kind::Kind, node::AnyTree)::NullableNode
    return kind(node) == node_kind ? node :
                haschildren(node) ? find_lhs_of_kind(node_kind, children(node)[1]) :
                    nothing
end

expr_depth(node::SyntaxNode)::Int = (! haschildren(node)) ? 1 :
                                        (1 + maximum(expr_depth.(children(node))))
expr_size(node::SyntaxNode)::Int = (! haschildren(node)) ? 1 :
                                        (1 + sum(expr_size.(children(node))))

"""
Gets a flat representation of the function argument nodes.

In particular, this is used to ensure that we get just the nodes without needing to think
of whether there are still named arguments in there.
"""
function get_flattened_fn_arg_nodes(function_node::SyntaxNode)::Vector{SyntaxNode}
    func_arguments = get_func_arguments(function_node)
    func_arg_nodes = []
    for arg in func_arguments
        # Parameters signifies keyword (also known as named) arguments.
        # All named arguments are then reported in subnodes. For now, we don't
        # treat them differently from positional arguments. This is underspecified.
        if kind(arg) == K"parameters"
            if ! haschildren(arg)
                continue
            end
            for child_arg in children(arg)
                push!(func_arg_nodes, child_arg)
            end
        else
            push!(func_arg_nodes, arg)
        end
    end
    return func_arg_nodes
end

"""
Gets string representations of all the arguments passed to a function node.
Returns these strings in the order it finds them.
"""
function get_string_fn_args(function_node::SyntaxNode)::Vector{String}
    return [get_string_arg(node) for node in get_flattened_fn_arg_nodes(function_node)]
end

"""
Gets a string representation of a single argument node.
Can be both:
* a node with leaves. Then it's likely type-annotated, and looks like (:: a Int64).
* a leaf node. Then it's an untyped argument and should be stringified to its own value.
"""
function get_string_arg(arg_node::SyntaxNode)::String
    if !is_leaf(arg_node)
        return string(first(children(arg_node)))
    else
        return string(arg_node)
    end
end

"""
Gets a string representation of the variable used within an assignment.
"""
function get_var_from_assignment(node::SyntaxNode)::NullableString
    if !is_assignment(node)
        return nothing
    end
    lhs = first(children(node))
    return string(lhs.data.val)
end

"""
Given a node, checks whether it's a mutating call. For instance:

push!(a, b) returns true.
length(a) returns false.

Naïve implementation. Does not recurse. Assumption is that we can trust
whether a function has been marked as mutating (so has the !).
Furthermore, the second child should be an identifier - otherwise we might
be checking against the actual function definition itself rather than its invocation.
"""
function is_mutating_call(node::SyntaxNode)::Bool
    return is_call(node) && _call_name_has_exclamation(node) && kind(children(node)[2]) == K"Identifier"
end

function _call_name_has_exclamation(call_node::SyntaxNode)::Bool
    call_name = get_call_name_from_call_node(call_node)
    # anonymous functions never have an exclamation point in front of them
    if isnothing(call_name)
        return false
    end
    return endswith(call_name, "!")
end

"""
Extracts the name of a call from the call node.

For instance, take the following node: push!(a, 1)
This is parsed as call (push! a 1). So to find the call,
"""
function get_call_name_from_call_node(call_node::SyntaxNode)::String
    call_type_node = first(children(call_node))
    call_name = string(call_type_node)
    return call_name
end

"""
    get_number(node::SyntaxNode)::Union{Number, Nothing}

Get the number from a literal node, or `nothing` if it cannot be parsed.
"""
function get_number(node::SyntaxNode)::Union{Number, Nothing}
    n = Meta.parse(sourcetext(node); raise=false)
    if typeof(n) == Expr
        if n.head == :error
            @debug "Couldn't parse number from node $(node): $(n.args[1].msg)"
        else
            @debug "Expected a number, got an expression: $n"
        end
        return nothing
    end
    return n
end

"""
    get_iteration_parts(for_loop::SyntaxNode)::Tuple{NullableNode, NullableNode}

Given a [for] node, return a pair where the first part is the loop variable (it
might be a tuple, if using `enumerate`, for instance), and the second part is the
iteration expression, which can be a collection object, a call to a function like
`eachindex`, a range, etc.

If the given node is not a [for] loop, or it has an unexpected shape, then both
returned parts are `nothing` (but it is still a pair).
"""
function get_iteration_parts(for_loop::SyntaxNode)::Tuple{NullableNode, NullableNode}
    if kind(for_loop) == K"for"
        if !( haschildren(for_loop) &&
              kind(first_child(for_loop)) == K"iteration"
           )
            @debug "for loop does not have an [iteration]" for_loop
            return nothing, nothing
        end
        node = first_child(for_loop)
        if !( haschildren(node) && kind(first_child(node)) == K"in" )
            @debug "for loop does not have an [iteration]/[in] sequence:" for_loop
            return nothing, nothing
        end
        node = first_child(node)
        if numchildren(node) != 2
            @debug "for loop [iteration/in] does not have exactly two children:" for_loop
            return nothing, nothing
        end
        var, expr = children(node)
        return var, expr
    end
end

end # module Properties
