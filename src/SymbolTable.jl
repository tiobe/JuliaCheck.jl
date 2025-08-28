module SymbolTable

import DataStructures: Stack
using JuliaSyntax: SyntaxNode, @K_str, children, head, kind, sourcetext
using ..Properties: find_lhs_of_kind, get_func_name, get_assignee, get_func_arguments,
    get_module_name, haschildren, is_assignment, is_function, is_global_decl, is_module,
    opens_scope

export SymbolTableStruct, enter_main_module!, exit_main_module!, update_symbol_table_on_node_enter!
export update_symbol_table_on_node_leave!, is_global

## Types

struct SymbolTableItem
    all_nodes::Vector{SyntaxNode}
end

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
The clear function assures that the symbol table is emptied between different
scopes. Not all scopes should be stacked on top of each other; sometimes it is
necessary to start with an empty scope.

Note that this is strictly a _temporary_ fix to avoid state issues. The symbol
table requires a bigger rework to deal with control flow rules.
"""

function clear_symbol_table!(table::SymbolTableStruct)
    table.stack = Stack{Module}()
end

"""
Module 'Main' is always there, at the bottom of the stack of modules.

This function makes sure to reflect that situation.
"""
function enter_main_module!(table::SymbolTableStruct)
    enter_module!(table, "Main")
end

"""
Push a new module (with its identifier) on top of the stack.

This introduces a new global scope (thus, a new stack of scopes).
"""
enter_module!(table::SymbolTableStruct, modjule::SyntaxNode)::Nothing = enter_module!(table, get_module_name(modjule)[2])
# Call the next method with the name (string) of the [module] node.

function enter_module!(table::SymbolTableStruct, name::AbstractString)::Nothing
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
scopes_within_module(table::SymbolTableStruct)::NestedScopes = current_module(table).nested_scopes

current_module(table::SymbolTableStruct)::Module = first(table.stack)

# TODO: a file can be `include`d into another, thus into another
# module and, what is most important from the point of view of the
# symbols table and declarations: something can be declared outside
# the file under analysis, and we will surely get confused about its
# scope.

function enter_scope!(table::SymbolTableStruct)
    push!(scopes_within_module(table), Scope())
end

function exit_scope!(table::SymbolTableStruct)
    pop!(scopes_within_module(table))
end

global_scope(table::SymbolTableStruct)::Scope = last(scopes_within_module(table))
current_scope(table::SymbolTableStruct)::Scope = first(scopes_within_module(table))

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
    scp = current_scope(table)
    return haskey(scp, var_node) && first(scp[var_node].all_nodes) === node
end

is_declared_in_current_scope(table::SymbolTableStruct, node::SyntaxNode)::Bool = _node_is_in_scope(node, current_scope(table))

is_global(table::SymbolTableStruct, node::SyntaxNode)::Bool = _node_is_in_scope(node, global_scope(table))

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
declare!(table::SymbolTableStruct, symbol::SyntaxNode) = declare!(table, current_scope(table), symbol)

function declare!(table::SymbolTableStruct, scp::Scope, node::SyntaxNode)
    symbol_id = _get_symbol_id(node)
    if haskey(scp, symbol_id)
        push!(scp[symbol_id].all_nodes, node)
    else
        scp[symbol_id] = SymbolTableItem([node])
    end
end

"""
Register a (change to a) global identifier.

Global identifiers have their own convenience method. Special checks exist on global variables,
and potentially global identifiers / variables might also be changed in a way that crosses through
the scope they are changed in.
"""
declare_global!(table::SymbolTableStruct, symbol::SyntaxNode) = declare!(table, global_scope(table), symbol)

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
        enter_module!(table, node)
    elseif is_function(node)
        _process_function!(table, node)
    elseif is_global_decl(node)
        _process_global!(table, node)
    elseif is_assignment(node)
        _process_assignment!(table, node)
    end
end

function _process_function!(table::SymbolTableStruct, node::SyntaxNode)
    fname = get_func_name(node)
    if !isnothing(fname)
        if kind(fname) == K"Identifier"
            declare!(table, fname)
        end
    end
    enter_scope!(table)
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
    arg = find_lhs_of_kind(K"Identifier", node)
    if isnothing(arg)
        return nothing
    end
    declare_global!(table, arg)
end

function _process_argument!(table::SymbolTableStruct, node::SyntaxNode)
    arg = find_lhs_of_kind(K"Identifier", node)
    if isnothing(arg)
        return nothing
    end
    declare!(table, arg)
end

function _process_assignment!(table::SymbolTableStruct, node::SyntaxNode)
    declare!(table, first(get_assignee(node)))
end

function _process_struct!(table::SymbolTableStruct, node::SyntaxNode)
    declare!(table, find_lhs_of_kind(K"Identifier", node))
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
        exit_scope!(table)
    end
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

end
