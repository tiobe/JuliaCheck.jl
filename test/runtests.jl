using Test: @testset, @test
using TestItems: @testitem
using IOCapture
using JuliaCheck
using JuliaSyntax: GreenNode, Kind, @K_str, SyntaxNode, parsestmt, JuliaSyntax as JS

include("../src/Properties.jl"); import .Properties
include("../src/Checks.jl"); import .Checks
include("../src/Process.jl"); import .Process
include("../src/SymbolTable.jl"); using .SymbolTable: declare!, enter_module!,
    enter_main_module!, enter_scope!, exit_module!, exit_main_module!,
    exit_scope!, is_declared, is_global, print_state

make_node(input::String)::SyntaxNode = parsestmt(SyntaxNode, input)

@testset "Symbols Table tests" begin

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

const COMPANY_PREFIX = "asml-"

@testset "Integration Tests" begin
    for f in readdir()
        if endswith(f, ".jl")
            fname = f[1:end-3]
            val_file = fname * ".val"
            if !isfile(val_file)
                continue
            end
            expected::String = ""
            try
                expected = read(val_file, String)
            catch x
                @warn "Cannot read '$val_file'. Skipping '$f'." x
                continue
            end
            corresponding_rule = COMPANY_PREFIX * replace(basename(fname), '_'=>'-')
            println("Checking '$f' with rule '$corresponding_rule'.")
            result = IOCapture.capture() do
                JuliaCheck.main(["--enable", corresponding_rule, "--", f])
            end
            @test chomp(result.output) == expected
        end
    end
end
