import Pkg
Pkg.add("DataStructures")

import DataStructures: Stack

## Types

## N.B.: Node must be defined before including this file.
# Each module introduces a new global scope. Nested modules can be represented
# by a stack, and local scopes are stacked, too, but those two stacks must be
# separated, they are orthogonal. The symbols table is a stack of sets, and it
# can be traversed top-down in search for a symbol. Then, each stacked module
# will have its own symbols table.
Scope = Set{Node}
SymbolsTable = Stack{Scope}


## Globals ##

symbols_table = SymbolsTable()
nested_modules = Stack{SymbolsTable}()


## Functions

enter_scope() = push!(symbols_table, Scope())
exit_scope()  = pop!(symbols_table)
global_scope()  = last(symbols_table)
current_scope() = first(symbols_table)

enter_module(_::Node) = push!(nested_modules, enter_scope())
exit_module() = pop!(nested_modules)

is_global(node::Node) = node ∈ global_scope()
is_declared(node::Node) = any(scope -> node ∈ scope, symbols_table)

add_to_scope(symbol::Node, scope::Scope = current_scope()) = push!(scope, symbol)

function declare(symbol::Node)
    # FIXME Remove `add_to_scope`, put the defaulted argument `scope` here, and
    # handle the `global` declaration outside of here, using the parent node.
    add_to_scope(symbol,
                 kind(symbol) == K"global" ? global_scope() : current_scope())
    return nothing
end
