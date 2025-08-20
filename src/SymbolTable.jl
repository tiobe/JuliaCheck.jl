module SymbolTable

import DataStructures: Stack
using JuliaSyntax: SyntaxNode, @K_str, children, haschildren, head, kind, sourcetext
using ...Properties: find_lhs_of_kind, get_func_name, get_assignee, get_func_arguments,
    get_module_name, is_assignment, is_function, is_module, opens_scope

export SymbolTableStruct, enter_main_module!, exit_main_module!, update_symbol_table_on_node_enter!, update_symbol_table_on_node_leave!

## Types

Item = SyntaxNode

#=
A scope is represented by a set of symbols (for now, each stored symbol is a
SyntaxNode, directly). Scopes are stacked, as they are nested, with the global
scope always at the base of that stack, and the current scope at the top.

Each module introduces a new global scope, and modules can be nested, like
scopes (but with names), so nested modules can be represented by a stack, too.

When searching for a symbol, we scan the stack of scopes of the current module,
top to bottom. Symbols from other modules have to be qualified, or entered into
the current module's global scope with a `using` declaration.
=#

Scope = Set{Item}
NestedScopes = Stack{Scope}
"""
A module containing an identifier and a stack of scopes.

The top of the scopes stack is the current scope, and the bottom is the global
scope for this module.
"""
struct Module
    mod_name::String
    nested_scopes::NestedScopes
end
Module(identifier::String) = Module(identifier, [Scope()])  # Start with global scope

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
    @assert length(table.stack) == length(scopes_within_module(table)) == 1 """
        There should be 1 module with 1 scope. Instead, there are $(length(SYMBOL_TABLE)) nested modules
        and $(length(scopes_within_module(table))) scopes.
        """
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
    @assert length(scopes_within_module(table)) == 1 "There should be one scope (the global one) on module entry."
    return nothing
end

"""
Leaving the 'Main' module happens only at the end of all processing: before
this, all other scopes and modules must be gone, and afterwards, everything
must be empty.
"""
function exit_main_module!(table::SymbolTableStruct)::Nothing
    @assert length(table.stack) == length(scopes_within_module(table)) == 1
    exit_module!(table)
    @assert isempty(table.stack)
    return nothing
end

"""
Leave a module, thus popping it from the stack.
"""
function exit_module!(table::SymbolTableStruct)::Nothing
    @assert !isempty(table.stack) "Somehow, the global scope is not there before leaving the module."
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

function enter_scope!(table::SymbolTableStruct)::Nothing
    push!(scopes_within_module(table), Scope())
    return nothing
end

function exit_scope!(table::SymbolTableStruct)::Nothing
    pop!(scopes_within_module(table))
    @assert !isempty(scopes_within_module(table)) "Exited global scope. This shouldn't happen before leaving the module!"
    return nothing
end

global_scope(table::SymbolTableStruct)::Scope = last(scopes_within_module(table))
current_scope(table::SymbolTableStruct)::Scope = first(scopes_within_module(table))

"""
Check if an item (the identifier in the node) is declared in any scope in the
current module.
"""
is_declared(table::SymbolTableStruct, node::Item)::Bool = !isempty(table.stack) && any(scp -> node ∈ scp, scopes_within_module(table))

is_declared_in_current_scope(table::SymbolTableStruct, node::Item)::Bool = node ∈ current_scope(table)

is_global(table::SymbolTableStruct, node::Item)::Bool = node ∈ global_scope(table)

"""
Register an identifier.
"""
declare!(table::SymbolTableStruct, symbol::Item) = declare!(table, current_scope(table), symbol)

function declare!(table::SymbolTableStruct, sc::Scope, symbol::Item)
    @assert kind(symbol) == K"Identifier" "kind(symbol) = $(kind(symbol))"
    push!(sc, symbol)
end

function update_symbol_table_on_node_enter!(table::SymbolTableStruct, node::SyntaxNode)
    if is_module(node)
        enter_module!(table, node)
    elseif is_function(node)
        _process_function!(table, node)
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
