using Test: @testset, @test
using TestItems: @testitem
# using JuliaCheck
using JuliaSyntax: GreenNode, Kind, @K_str, SyntaxNode, parsestmt, JuliaSyntax as JS

include("../src/Properties.jl"); import .Properties
# include("../src/Checks.jl"); import .Checks
include("../src/Process.jl"); import .Process
include("../src/SymbolTable.jl"); import .SymbolTable

make_node(input::String) = parsestmt(SyntaxNode, input)

@testitem "Symbols Table tests" begin

    # Add some identifiers to Main module, global scope
    SymbolTable.enter_main_module!()
    SymbolTable.declare!(make_node("x"))
    SymbolTable.declare!(make_node("y"))
    stt = SymbolTable.print_state()
    @test SymbolTable.print_state() == """
        Symbol Table State:
        Module stack (1 modules):
        [1] Module: Main <- current
            Scope stack (1 scopes):
            [1] Scope (global): {y, x} <- current
        """

    #= Push a new scope in Main module
    enter_scope!()
    declare!("z")
    declare!("x")  # Shadow the global x
    println("Pushed new scope, added 'z' and 'x' (shadowing global)")
    print_state()

    # Test identifier lookup
    println("Identifier lookup in current module:")
    for id in ["x", "y", "z", "w"]
        level = find_identifier(id)
        if level > 0
            println("  '$id' found at scope level $level")
        else
            println("  '$id' not found")
        end
    end
    println()

    # Push a new module
    enter_module!("MyModule")
    declare!("a")
    declare!("b")
    println("Pushed new module 'MyModule', added 'a' and 'b'")
    print_state()

    # Pop module
    exit_module!()
    println("Popped module")
    print_state()

    # Pop scope in Main module, then leave the module itself.
    exit_scope!()
    println("Popped scope from global module")
    print_state()

    exit_main_module!()
    println("Left Main module")
    print_state()
    =#
end

@testset "Integration Tests" begin
    # TODO move here the loop to check each Julia file with a .val counterpart
    #include("use_isinf_to_check_for_infinite.jl")
end
