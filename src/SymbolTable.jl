module SymbolTable

import DataStructures: Stack
using JuliaSyntax: SyntaxNode, @K_str, children, head, kind, sourcetext
using ..Properties: get_module_name

export is_declared_in_current_scope, current_module, current_scope, declare!, is_declared,
    enter_main_module!, enter_module!, enter_scope!, exit_main_module!, exit_module!,
    exit_scope!

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


## Globals ##

SYMBOL_TABLE = Stack{Module}()


## Functions

"""
The clear function assures that the symbol table is emptied between different
scopes. Not all scopes should be stacked on top of each other; sometimes it is
necessary to start with an empty scope.

Note that this is strictly a _temporary_ fix to avoid state issues. The symbol
table requires a bigger rework to deal with control flow rules.
"""

function clear_symbol_table!()
    SYMBOL_TABLE = Stack{Module}()
end

"""
Module 'Main' is always there, at the bottom of the stack of modules.

This function makes sure to reflect that situation.
"""
function enter_main_module!()
    enter_module!("Main")
    @assert length(SYMBOL_TABLE) == length(scopes_within_module()) == 1 """
        There should be 1 module with 1 scope. Instead, there are $(length(SYMBOL_TABLE)) nested modules
        and $(length(scopes_within_module())) scopes.
        """
end

"""
Push a new module (with its identifier) on top of the stack.

This introduces a new global scope (thus, a new stack of scopes).
"""
enter_module!(modjule::SyntaxNode)::Nothing = enter_module!(get_module_name(modjule)[2])
# Call the next method with the name (string) of the [module] node.

function enter_module!(name::AbstractString)::Nothing
    new_sym_table = NestedScopes()
    push!(new_sym_table, Scope())   # TODO find out why the Module constructor
                                    # above doesn't add a scope, despite how it
                                    # looks like that is what happens.
    push!(SYMBOL_TABLE, Module(name, new_sym_table))
    @assert length(scopes_within_module()) == 1 "There should be one scope (the global one) on module entry."
    return nothing
end

"""
Leaving the 'Main' module happens only at the end of all processing: before
this, all other scopes and modules must be gone, and afterwards, everything
must be empty.
"""
function exit_main_module!()::Nothing
    @assert length(SYMBOL_TABLE) == length(scopes_within_module()) == 1
    exit_module!()
    @assert isempty(SYMBOL_TABLE)
    return nothing
end

"""
Leave a module, thus popping it from the stack.
"""
function exit_module!()::Nothing
    @assert !isempty(SYMBOL_TABLE) "Somehow, the global scope is not there before leaving the module."
    pop!(SYMBOL_TABLE)
    return nothing
end

"""
Return the symbols table for the current module.

The current module is the one at the peak of the stack of modules.
"""
scopes_within_module()::NestedScopes = current_module().nested_scopes

current_module()::Module = first(SYMBOL_TABLE)

# TODO: a file can be `include`d into another, thus into another
# module and, what is most important from the point of view of the
# symbols table and declarations: something can be declared outside
# the file under analysis, and we will surely get confused about its
# scope.

function enter_scope!()::Nothing
    push!(scopes_within_module(), Scope())
    return nothing
end

function exit_scope!()::Nothing
    pop!(scopes_within_module())
    @assert !isempty(scopes_within_module()) "Exited global scope. This shouldn't happen before leaving the module!"
    return nothing
end

global_scope()::Scope = last(scopes_within_module())
current_scope()::Scope = first(scopes_within_module())

"""
Check if an item (the identifier in the node) is declared in any scope in the
current module.
"""
is_declared(node::Item)::Bool = !isempty(SYMBOL_TABLE) && any(scp -> node ∈ scp, scopes_within_module())

is_declared_in_current_scope(node::Item)::Bool = node ∈ current_scope()

is_global(node::Item)::Bool = node ∈ global_scope()

"""
Register an identifier.
"""
declare!(symbol::Item) = declare!(current_scope(), symbol)

function declare!(sc::Scope, symbol::Item)
    @assert kind(symbol) == K"Identifier" "kind(symbol) = $(kind(symbol))"
    push!(sc, symbol)
end

"""
Display the current state of the symbols table.
"""
function print_state()::String
    state = """
        Symbol Table State:
        Module stack ($(length(SYMBOL_TABLE)) modules):
        """
    for (i, mod) in enumerate(SYMBOL_TABLE)
        marker = i == length(SYMBOL_TABLE) ? " <- current" : ""
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
