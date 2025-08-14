using Test: @test #, @testset
using TestItems: @testitem
using TestItemRunner
using JuliaCheck


@testitem "Symbols Table tests" begin
    using JuliaSyntax: GreenNode, Kind, @K_str, SyntaxNode, parsestmt,
        JuliaSyntax as JS
    include("../src/LosslessTrees.jl")
    include("../src/Properties.jl")
    include("../src/SymbolTable.jl"); using .SymbolTable: clear_symbol_table!,
        declare!, enter_module!, enter_main_module!, enter_scope!, exit_module!,
        exit_main_module!, exit_scope!, is_declared, is_global, print_state

    make_node(input::String)::SyntaxNode = parsestmt(SyntaxNode, input)

    # Ensure we always start from a clean symbol table.
    # If run multiple times, contents of the symbol table are not as expected.
    clear_symbol_table!()

    # Add some identifiers to Main module, global scope
    enter_main_module!()
    x = make_node("x")
    y = make_node("y")
    declare!(x)
    declare!(y)
    @test print_state() == """
        Symbol Table State:
        Module stack (1 modules):
            [1] Module: Main <- current
                Scope stack (1 scopes):
                    [1] Scope (global): {y, x} <- current
        """

    # Push a new scope in Main module
    enter_scope!()
    z = make_node("z")
    declare!(z)
    declare!(x)  # Shadow the global x
    @test print_state() == """
        Symbol Table State:
        Module stack (1 modules):
            [1] Module: Main <- current
                Scope stack (2 scopes):
                    [1] Scope: {z, x} <- current
                    [2] Scope (global): {y, x}
        """

    # Test identifier lookup
    @test is_declared(x)
    @test is_declared(y)
    @test is_declared(z)
    @test ! is_declared(make_node("w"))
    @test is_global(x)  # This might not be valid in the future, since 'x' is shadowed
    @test is_global(y)
    @test ! is_global(z)

    # Push a new module, declare two more identifiers
    enter_module!("MyModule")
    declare!(make_node("a"))
    declare!(make_node("b"))
    @test print_state() == """
        Symbol Table State:
        Module stack (2 modules):
            [1] Module: MyModule
                Scope stack (1 scopes):
                    [1] Scope (global): {a, b} <- current
            [2] Module: Main <- current
                Scope stack (2 scopes):
                    [1] Scope: {z, x} <- current
                    [2] Scope (global): {y, x}
        """

    # Pop module
    exit_module!()
    @test print_state() == """
        Symbol Table State:
        Module stack (1 modules):
            [1] Module: Main <- current
                Scope stack (2 scopes):
                    [1] Scope: {z, x} <- current
                    [2] Scope (global): {y, x}
        """

    # Pop scope in Main module, then exit the module itself.
    exit_scope!()
    @test print_state() == """
        Symbol Table State:
        Module stack (1 modules):
            [1] Module: Main <- current
                Scope stack (1 scopes):
                    [1] Scope (global): {y, x} <- current
        """

    exit_main_module!()
    @test print_state() == """
        Symbol Table State:
        Module stack (0 modules):
        """
end


@testitem "Numbers" begin
    using JuliaSyntax: SyntaxNode, parsestmt
    include("../src/LosslessTrees.jl")
    include("../src/Properties.jl"); using .Properties: get_number
    include("../src/SymbolTable.jl"); using .SymbolTable: declare!, enter_module!,
        enter_main_module!, enter_scope!, exit_module!, exit_main_module!,
        exit_scope!, is_declared, is_global, print_state

    make_node(input::String)::SyntaxNode = parsestmt(SyntaxNode, input)

    @test get_number(make_node("4.493_775_893_684_088e16")) == 4.493775893684088e16
end


@testitem "Integration Tests" begin
    import IOCapture

    for f in readdir(@__DIR__)
        if endswith(f, ".val")
            fname = f[1:end-4]
            in_file = fname * ".jl"
            expected::String = ""
            try
                expected = read(f, String)
            catch x
                @warn x
                continue
            end
            corresponding_rule = replace(basename(fname), '_'=>'-')
            println(join(["--enable", corresponding_rule, "--", in_file], " "))
            result = IOCapture.capture() do
                JuliaCheck.main(["--enable", corresponding_rule, "--", in_file])
            end
            @test chomp(result.output) == expected
        end
    end
end

@run_package_tests
