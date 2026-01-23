module SymbolTable

import DataStructures: Stack

using JuliaSyntax: SyntaxNode, @K_str, children, head, kind, sourcetext
using ..Properties: find_lhs_of_kind, get_func_name, get_assignee, get_func_arguments,
    get_module_name, get_var_from_assignment, haschildren, is_assignment, is_function,
    is_global_decl, is_module, opens_scope, is_mod_toplevel
using ..SyntaxNodeHelpers: ancestors, find_descendants, get_all_assignees
using ..TypeHelpers: get_variable_type_from_node, is_different_type, TypeSpecifier

export Module, SymbolTableItem, SymbolTableStruct, enter_main_module!, exit_main_module!, update_symbol_table_on_node_enter!
export update_symbol_table_on_node_leave!, is_global, type_has_changed_from_init, get_initial_type_of_node

struct SymbolTableItem
    declaration_node::SyntaxNode # The node where this symbol was first seen and thus declared
    all_nodes::Vector{SyntaxNode} # Keep a set of all nodes that we encounter for this symbol
    initial_type::TypeSpecifier
end
SymbolTableItem(node, type) = SymbolTableItem(node, Vector{SyntaxNode}([node]), type)

#=
A scope is represented by a vector (because we would like to keep the ordering!)
of symbols (for now, each stored symbol is a SyntaxNode, directly).
Scopes are stacked, as they are nested, with the global
scope always at the base of that stack, and the current scope at the top.

Each module introduces a new global scope, and modules can be nested, like
scopes (but with names), so nested modules can be represented by a stack, too.

When searching for a symbol, we scan the stack of scopes of the current module,
top to bottom. Symbols from other modules have to be qualified, or entered into
the current module's global scope with a `using` declaration.
=#

Scope = Dict{String, SymbolTableItem}
NestedScopes = Stack{Scope}
"""
A module containing an identifier and a stack of scopes.

The top of the scopes stack is the current scope, and the bottom is the global
scope for this module. There is a stack of scopes to reflect the fact that there are
multiple nested scopes within a module (eg. various constructs within the module itself -
a function with a for loop in it, with another let construct in there)
"""
struct Module
    mod_name::String
    nested_scopes::NestedScopes
end
Module(identifier::String) = Module(identifier, [Scope()])  # Start with global scope

"""
A symbol table structure currently containing the basic stack of scopes.

Keeps it extendable in the case there are rules that contain more.

Visual representation of the SymbolTableStruct for convenience:

SymbolTableStruct
 |--Module (name)
 | >--NestedScopes
 |    >--Scope
 |       >--variable a: (all_nodes)
 |          node (declaration of variable a)
 |          node (mutation of variable a)
 |       >--variable b: (all_nodes)
 |          node (declaration of variable b)
 |    >--Scope
 |       >--variable c: (all_nodes)
 |          node (declaration of variable c)
 |       >--variable a: (all_nodes)
 |          node (local declaration of variable a)
 |          node (local mutation of variable a)
 |--Module (name2)
 ...

"""
struct SymbolTableStruct
    stack::Stack{Module}

    SymbolTableStruct() = new(Stack{Module}())
end

## Functions

"""
Module 'Main' is always there, at the bottom of the stack of modules.

This function makes sure to reflect that situation.
"""
function enter_main_module!(table::SymbolTableStruct)
    _enter_module!(table, "Main")
end

"""
Push a new module (with its identifier) on top of the stack.

This introduces a new global scope (thus, a new stack of scopes).
"""
_enter_module!(table::SymbolTableStruct, modjule::SyntaxNode)::Nothing = _enter_module!(table, get_module_name(modjule)[2])
# Call the next method with the name (string) of the [module] node.

function _enter_module!(table::SymbolTableStruct, name::AbstractString)::Nothing
    new_sym_table = NestedScopes()
    push!(new_sym_table, Scope())
    push!(table.stack, Module(name, new_sym_table))
    return nothing
end

"""
Leaving the 'Main' module happens only at the end of all processing: before
this, all other scopes and modules must be gone, and afterwards, everything
must be empty.
"""
function exit_main_module!(table::SymbolTableStruct)::Nothing
    exit_module!(table)
    return nothing
end

"""
Leave a module, thus popping it from the stack.
"""
function exit_module!(table::SymbolTableStruct)::Nothing
    pop!(table.stack)
    return nothing
end

"""
Return the symbols table for the current module.

The current module is the one at the peak of the stack of modules.
"""
scopes_within_module(table::SymbolTableStruct)::NestedScopes = _current_module(table).nested_scopes

_current_module(table::SymbolTableStruct)::Module = first(table.stack)

#=
TODO: a file can be `include`d into another, thus into another
module and, what is most important from the point of view of the
symbols table and declarations: something can be declared outside
the file under analysis, and we will surely get confused about its
scope.
=#

function _enter_scope!(table::SymbolTableStruct)
    push!(scopes_within_module(table), Scope())
end

function _exit_scope!(table::SymbolTableStruct)
    pop!(scopes_within_module(table))
end

_global_scope(table::SymbolTableStruct)::Scope = last(scopes_within_module(table))
_current_scope(table::SymbolTableStruct)::Scope = first(scopes_within_module(table))

"""
Check if an item (the identifier in the node) is declared in any scope in the
current module.
"""
function is_declared(table::SymbolTableStruct, node::SyntaxNode)::Bool
    return !isempty(table.stack) && any(scp -> _node_is_in_scope(node, scp), scopes_within_module(table))
end

"""
Check if an item is the declaration (ie. the first assignment) of a variable
within the given scope. This is a common operation, as often we wish to check
whether a declaration meets certain requirements, and we wish to be able to
treat the first item (ie. the declaration) different from others - as we
then want to check whether certain operations might be redefining.
"""
function node_is_declaration_of_variable(table::SymbolTableStruct, node::SyntaxNode)::Bool
    var_node = string(node.data.val)
    scp = _current_scope(table)
    return haskey(scp, var_node) && scp[var_node].declaration_node === node
end

_is_declared_in_current_scope(table::SymbolTableStruct, node::SyntaxNode)::Bool = _node_is_in_scope(node, _current_scope(table))

is_global(table::SymbolTableStruct, node::SyntaxNode)::Bool = _node_is_in_scope(node, _global_scope(table))

function _node_is_in_scope(node::SyntaxNode, scp::Scope)::Bool
    symbol_id = _get_symbol_id(node)
    if haskey(scp, symbol_id)
        return node ∈ scp[symbol_id].all_nodes
    end
    return false
end

"""
Register an identifier.
"""
_declare!(table::SymbolTableStruct, symbol::SyntaxNode) = _declare_on_scope!(_current_scope(table), symbol, nothing)

function _declare_on_scope!(scp::Scope, node::SyntaxNode, type_spec::TypeSpecifier)
    symbol_id = _get_symbol_id(node)
    if haskey(scp, symbol_id)
        push!(scp[symbol_id].all_nodes, node)
    else
        scp[symbol_id] = SymbolTableItem(node, type_spec)
    end
end


"""
Register a (change to a) global identifier.

Global identifiers have their own convenience method. Special checks exist on global variables,
and potentially global identifiers / variables might also be changed in a way that crosses through
the scope they are changed in.
"""
_declare_global!(table::SymbolTableStruct, symbol::SyntaxNode) = _declare_on_scope!(_global_scope(table), symbol, nothing)

_get_symbol_id(node::SyntaxNode)::String = string(node)

"""
Handles symbol table updates when a new node is entered.

The idea is that this function slots into the DFS used to walk through
the abstract syntax tree. When a node is hit, this ensures that the
syntax tree is updated as expected.

The reason why this cannot easily be done as a part of other functionality
(for example, also making this use predicate behaviour like the rules do)
is that there is also a necessity to have this work on _exiting_ a node
while preserving the state in between.

Currently logs new modules, functions, and (global) variables.
"""
function update_symbol_table_on_node_enter!(table::SymbolTableStruct, node::SyntaxNode)
    if is_module(node)
        _enter_module!(table, node)
    elseif is_function(node)
        _process_function!(table, node)
    elseif is_global_decl(node)
        _process_global!(table, node)
    elseif is_assignment(node)
        is_assignment_to_global = any(n -> kind(n) == K"global", ancestors(node)) ||
            is_mod_toplevel(node.parent) # Top-level assignment defines a global variable
        scope = is_assignment_to_global ? _global_scope(table) : _current_scope(table)
        _process_assignment!(scope, node)
    end
end

function _process_function!(table::SymbolTableStruct, node::SyntaxNode)
    fname = get_func_name(node)
    if !isnothing(fname)
        if kind(fname) == K"Identifier"
            _declare!(table, fname)
        end
    end
    _enter_scope!(table)
    for arg in get_func_arguments(node)
        if kind(arg) == K"parameters"
            if ! haschildren(arg)
                return nothing
            end
            # The last argument in the list is itself a list, of named arguments.
            for arg in children(arg)
                _process_argument!(table, arg)
            end
        else
            _process_argument!(table, arg)
        end
    end
end

function _process_global!(table::SymbolTableStruct, node::SyntaxNode)
    # Handle statements like `global x, y = 1, 2`
    # We need to handle assignment here and cannot wait until the descendant 'assignment' expression
    # is encountered in `update_symbol_table_on_node_enter!`, because the check might listen to `is_global_decl` event.
    assignments = find_descendants(n -> kind(n) == K"=", node)
    for assignment in assignments
        _process_assignment!(_global_scope(table), assignment)
    end

    # Handle statements like 'global x, y'
    if length(assignments) == 0
        for c in something(node.children, [])
            _declare_global!(table, c)
        end
    end
end

function _process_argument!(table::SymbolTableStruct, node::SyntaxNode)
    arg = find_lhs_of_kind(K"Identifier", node)
    if isnothing(arg)
        return nothing
    end
    _declare!(table, arg)
end

function _process_assignment!(scope::Scope, node::SyntaxNode)
    @assert kind(node) == K"=" "Expected a [=] node, got [$(kind(node))]."
    assignees = get_all_assignees(node)
    if length(assignees) == 1
        # For now, we can only infer the type for statements with only one assignee
        var_node = first(assignees)
        type_of_node = get_variable_type_from_node(node)
        _declare_on_scope!(scope, var_node, type_of_node)
    else
        # In case of multiple assignees, we register the variables, but without a type for now
        for var_node in assignees
            _declare_on_scope!(scope, var_node, nothing)
        end
    end
end

function _process_struct!(table::SymbolTableStruct, node::SyntaxNode)
    _declare!(table, find_lhs_of_kind(K"Identifier", node))
end

"""
Handles symbol table updates when a node is exited.

When a module or a scope-opening function is left, this is then
used to exit scopes and move back to the table below it (so scoped
variables within the current scope are no longer present then).
"""
function update_symbol_table_on_node_leave!(table::SymbolTableStruct, node::SyntaxNode)
    if is_module(node)
        exit_module!(table)
    elseif opens_scope(node)
        _exit_scope!(table)
    end
end

function get_initial_type_of_node(table::SymbolTableStruct, assignment_node::SyntaxNode)::TypeSpecifier
    scp = _current_scope(table)
    var_node = get_var_from_assignment(assignment_node)
    if !isnothing(var_node) && haskey(scp, var_node)
        return scp[var_node].initial_type
    end
    return nothing
end

function type_has_changed_from_init(table::SymbolTableStruct, assignment_node::SyntaxNode)::Bool
    scp = _current_scope(table)
    var_node = get_var_from_assignment(assignment_node)
    if !isnothing(var_node) && haskey(scp, var_node)
        current_type = get_variable_type_from_node(assignment_node)
        return is_different_type(scp[var_node].initial_type, current_type)
    end
    return false
end

"""
Display the current state of the symbols table.
"""
function print_state(table::SymbolTableStruct)::String
    state = """
        Symbol Table State:
        Module stack ($(length(table.stack)) modules):
        """
    for (i, mod) in enumerate(table.stack)
        marker = i == length(table.stack) ? " <- current" : ""
        state *= """
                [$i] Module: $(mod.mod_name)$marker
                    Scope stack ($(length(mod.nested_scopes)) scopes):
            """
        for (j, scope) in enumerate(mod.nested_scopes)
            scope_marker = j == 1 ? " <- current" : ""
            scope_type = j == length(mod.nested_scopes) ? " (global)" : ""
            ids = isempty(scope) ? "{}" : "{$(join(collect(scope), ", "))}"
            state *= "            [$j] Scope$scope_type: $ids$scope_marker\n"
        end
    end
    return state
end

end # module SymbolTable
