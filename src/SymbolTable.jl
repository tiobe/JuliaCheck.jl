module SymbolTable

# import Pkg
# Pkg.add("DataStructures")
import DataStructures: Stack

using JuliaSyntax: SyntaxNode, @K_str, children, head, kind, sourcetext

export declare, is_declared, exit_module

## Types

# Each module introduces a new global scope. Nested modules can be represented
# by a stack, and local scopes are stacked, too, but those two stacks must be
# separated, they are orthogonal. The symbols table is a stack of sets, and it
# can be traversed top-down in search for a symbol. Then, each stacked module
# will have its own symbols table.
Scope = Set{SyntaxNode}
SymbolsTable = Stack{Scope}


## Globals ##

symbols_table = SymbolsTable()
nested_modules = Stack{SymbolsTable}()


## Functions

function enter_scope()
    push!(symbols_table, Scope())
    @debug "{\n" length(nested_modules) length(symbols_table)
end
function exit_scope()
    pop!(symbols_table)
    @debug "}\n" length(nested_modules) length(symbols_table)
end
global_scope()  = last(symbols_table)
current_scope() = first(symbols_table)

function enter_module()
    enter_module("Main")
    @assert length(nested_modules) == 1 && length(symbols_table) == 1 "There should be "*
    "1 module with 1 scope. Instead, there are $(length(nested_modules)) nested modules"*
    " and $(length(symbols_table)) scopes."
end
enter_module(modjule::SyntaxNode) = enter_module(sourcetext(children(modjule)[1]))
function enter_module(name::AbstractString)
    @debug " -> Entering module $name"
    push!(nested_modules, enter_scope())
end

function exit_module()
    leave_module("Main")
    @assert length(nested_modules) == 0 && length(symbols_table) == 0
end
exit_module(modjule::SyntaxNode) = leave_module(sourcetext(children(modjule)[1]))
function leave_module(name::String)
    @debug " <- Leaving module $name"
    pop!(nested_modules)
end

is_global(node::SyntaxNode) = node ∈ global_scope()
is_declared(node::SyntaxNode) = any(scope -> node ∈ scope, symbols_table)

add_to_scope(symbol::SyntaxNode, scope::Scope = current_scope()) = push!(scope, symbol)

function declare(symbol::SyntaxNode)
    # FIXME Remove `add_to_scope`, put the defaulted argument `scope` here, and
    # handle the `global` declaration outside of here, using the parent node.
    add_to_scope(symbol,
                 kind(symbol) == K"global" ? global_scope() : current_scope())
    return nothing
end

end
