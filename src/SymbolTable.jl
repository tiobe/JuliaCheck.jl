module SymbolTable

import DataStructures: Stack
using JuliaSyntax: SyntaxNode, @K_str, children, head, kind, sourcetext
include("Properties.jl"); using .Properties: get_module_name

export current_module, current_scope, declare!, is_declared, enter_main_module!,
    enter_module!, enter_scope!, exit_main_module!, exit_module!, exit_scope!

## Types

Item = SyntaxNode

# Each module introduces a new global scope. Nested modules can be represented
# by a stack, and local scopes are stacked, too, but those two stacks must be
# separated, they are orthogonal. The symbols table is a stack of sets, and it
# can be traversed top-down in search for a symbol. Then, each stacked module
# will have its own symbols table, with always at least the global scope.
Scope = Set{Item}
SymbolsTable = Stack{Scope}
"""
A module containing an identifier and a stack of scopes (symbol table).
The bottom of the scope stack is the global scope for this module.
"""
struct Module
    mod_name::String
    table::SymbolsTable
end
Module(identifier::String) = Module(identifier, [Scope()])  # Start with global scope


## Globals ##

NESTED_MODULES = Stack{Module}()


## Functions

"""
Module 'Main' is always there, at the bottom of the stack of modules.
This function makes sure to reflect that situation.
"""
function enter_main_module!()
    enter_module!("Main")
    @assert length(NESTED_MODULES) == length(symbols_table()) == 1 """
        There should be 1 module with 1 scope. Instead, there are $(length(NESTED_MODULES)) nested modules and $(length(symbols_table())) scopes.
    """
end

"""
Push a new module (with its identifier) on top of the stack.
This introduces a new global scope (and a new stack of scopes).
"""
enter_module!(modjule::SyntaxNode)::Nothing = enter_module!(get_module_name(modjule)[2])
# Call the next method with the name (string) of the [module] node.

function enter_module!(name::AbstractString)::Nothing
    new_sym_table = SymbolsTable()
    push!(new_sym_table, Scope())   # TODO find out why the Module constructor
                                    # above doesn't add a scope, despite how it
                                    # looks like that is what happens.
    push!(NESTED_MODULES, Module(name, new_sym_table))
    @assert length(symbols_table()) == 1 "There should be one scope (the global one) on module entry."
    return nothing
end

"""
Leaving the 'Main' module happens only at the end of all processing: before
this, all other scopes and modules must be gone, and afterwards, everything
must be empty.
"""
function exit_main_module!()::Nothing
    @assert length(NESTED_MODULES) == length(symbols_table()) == 1
    exit_module!()
    @assert isempty(NESTED_MODULES)
    return nothing
end

"""
Leave a module, thus popping it from the stack.
"""
function exit_module!()::Nothing
    @assert !isempty(NESTED_MODULES) "Somehow, the global scope is not there before leaving the module."
    left_mod = pop!(NESTED_MODULES)
    return nothing
end

"""
Return the symbols table for the current module.
The current module is the one at the peak of the stack of modules.
"""
symbols_table()::SymbolsTable = current_module().table

current_module()::Module = first(NESTED_MODULES)

# TODO: a file can be `include`d into another, thus into another
# module and, what is most important from the point of view of the
# symbols table and declarations: something can be declared outside
# the file under analysis, and we will surely get confused about its
# scope.

function enter_scope!()::Nothing
    push!(symbols_table(), Scope())
    return nothing
end

function exit_scope!()::Nothing
    pop!(symbols_table())
    @assert !isempty(symbols_table()) "Exited global scope. This shouldn't happen!"
    return nothing
end

global_scope()::Scope = last(symbols_table())
current_scope()::Scope = first(symbols_table())

is_global(node::Item)::Bool = node ∈ global_scope()

"""
Check if an identifier exists in any scope in the current module.
Returns the scope level where found (1 is current, the higher the shallower
nested), or 0 if not found.
"""
function find_identifier(identifier::String)::Int
    for (i, scope) in enumerate(current_module().table)
        if identifier ∈ scope
            return i
        end
    end
    return 0
end
# TODO Turn String's into Symbol's for identifiers?

"""
Check if an item (the identifier in the node) is declared in any scope in the
current module.
"""
is_declared(node::Item)::Bool = 0 < find_identifier(string(node))

"""
Register an identifier.
"""
declare!(symbol::Item) = declare!(current_scope(), symbol)

function declare!(sc::Scope, symbol::Item)
    @assert kind(symbol) == K"Identifier"
    push!(sc, symbol) # TODO Symbol(symbol))
end

"""
Display the current state of the symbols table.
"""
function print_state()::String
    state = """
        Symbol Table State:
        Module stack ($(length(NESTED_MODULES)) modules):
        """
    for (i, mod) in enumerate(NESTED_MODULES)
        marker = i == length(NESTED_MODULES) ? " <- current" : ""
        state *= """
              [$i] Module: $(mod.mod_name)$marker
                Scope stack ($(length(mod.table)) scopes):
            """
        for (j, scope) in enumerate(mod.table)
            scope_marker = j == 1 ? " <- current" : ""
            scope_type = j == length(mod.table) ? " (global)" : ""
            ids = isempty(scope) ? "{}" : "{$(join(collect(scope), ", "))}"
            state *= "      [$j] Scope$scope_type: $ids$scope_marker"
        end
    end
    return state
end

end
