using Test: @test #, @testset
using TestItems: @testitem
using TestItemRunner
using JuliaCheck
include("../src/Properties.jl"); import .Properties
include("../src/Checks.jl"); import .Checks
include("../src/Process.jl"); import .Process

@testitem "Symbols Table tests" begin
    using JuliaSyntax: GreenNode, Kind, @K_str, SyntaxNode, parsestmt,
        JuliaSyntax as JS
    include("../src/SymbolTable.jl"); using .SymbolTable: declare!, enter_module!,
        enter_main_module!, enter_scope!, exit_module!, exit_main_module!,
        exit_scope!, is_declared, is_global, print_state

    make_node(input::String)::SyntaxNode = parsestmt(SyntaxNode, input)

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
