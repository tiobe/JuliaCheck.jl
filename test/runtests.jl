using Test: @test #, @testset
using TestItems: @testitem
using TestItemRunner
using JuliaCheck


@testitem "Symbols Table tests" begin
    using JuliaSyntax: GreenNode, Kind, @K_str, SyntaxNode, parsestmt,
        JuliaSyntax as JS
    include("../src/LosslessTrees.jl")
    include("../src/Properties.jl")
    include("../src/SymbolTable.jl"); using .SymbolTable: is_declared_in_current_scope,
        clear_symbol_table!, declare!, enter_module!, enter_main_module!, enter_scope!,
        exit_module!, exit_main_module!, exit_scope!, is_declared, is_global, SymbolTableStruct

    make_node(input::String)::SyntaxNode = parsestmt(SyntaxNode, input)

    # Ensure we always start from a clean symbol table.
    # If run multiple times, contents of the symbol table are not as expected.
    table = SymbolTableStruct()

    # Add some identifiers to Main module, global scope
    enter_main_module!(table)
    x = make_node("x")
    y = make_node("y")
    declare!(table, x)
    declare!(table, y)

    # Push a new scope in Main module
    # State expectations:
    # Symbol Table State:
    #    Module stack (1 modules):
    #        [1] Module: Main <- current
    #            Scope stack (2 scopes):
    #                [1] Scope: {z, x} <- current
    #                [2] Scope (global): {y, x}
    enter_scope!(table)
    z = make_node("z")
    declare!(table, z)
    declare!(table, x)

    @test is_declared(table, x)
    @test is_declared(table, y)
    @test is_declared(table, z)
    @test ! is_declared(table, make_node("w"))
    @test is_global(table, x)  # This might not be valid in the future, since 'x' is shadowed
    @test is_global(table, y)
    @test ! is_global(table, z)

    # Push a new module, declare two more identifiers. These should be global to this module.
    # State expectations:
    # Symbol Table State:
    #    Module stack (2 modules):
    #        [1] Module: MyModule
    #            Scope stack (1 scopes):
    #                [1] Scope (global): {a, b} <- current
    #        [2] Module: Main <- current
    #            Scope stack (2 scopes):
    #                [1] Scope: {z, x} <- current
    #                [2] Scope (global): {y, x}

    enter_module!(table, "MyModule")
    a = make_node("a")
    b = make_node("b")
    declare!(table, a)
    declare!(table, b)

    @test is_declared(table, a)
    @test is_declared(table, b)

    @test is_declared_in_current_scope(table, a)
    @test is_declared_in_current_scope(table, b)

    @test !is_declared_in_current_scope(table, x)
    @test !is_declared_in_current_scope(table, y)
    @test !is_declared_in_current_scope(table, z)

    @test is_global(table, a)
    @test is_global(table, b)

    # Pop module
    # State expectations:
    # Symbol Table State:
    #    Module stack (1 modules):
    #        [1] Module: Main <- current
    #            Scope stack (2 scopes):
    #                [1] Scope: {z, x} <- current
    #                [2] Scope (global): {y, x}

    exit_module!(table)
    @test !is_declared(table, a)
    @test !is_declared(table, b)
    @test is_declared_in_current_scope(table, x)
    @test is_declared(table, y)
    @test !is_declared_in_current_scope(table, y)
    @test is_declared_in_current_scope(table, z)

    # Pop scope in Main module, then exit the module itself.
    # State expectations:
    # Symbol Table State:
    #    Module stack (1 modules):
    #        [1] Module: Main <- current
    #            Scope stack (1 scopes):
    #                [1] Scope (global): {y, x} <- current

    exit_scope!(table)
    @test is_declared(table, x)
    @test is_declared(table, y)
    @test !is_declared(table, z)

    # Finally, exit the main module, and nothing should be declared here anymore.
    exit_main_module!(table)
    @test !is_declared(table, x)
    @test !is_declared(table, y)
end


@testitem "Numbers" begin
    using JuliaSyntax: SyntaxNode, parsestmt
    include("../src/LosslessTrees.jl")
    include("../src/Properties.jl"); using .Properties: get_number
    include("../src/SymbolTable.jl"); using .SymbolTable: declare!, enter_module!,
        enter_main_module!, enter_scope!, exit_module!, exit_main_module!,
        exit_scope!, is_declared, is_global

    make_node(input::String)::SyntaxNode = parsestmt(SyntaxNode, input)

    @test get_number(make_node("4.493_775_893_684_088e16")) == 4.493775893684088e16
end


@testitem "Golden File Tests" begin
    import IOCapture
    normalize(text) = strip(replace(replace(text, "\r\n" => "\n"))) * "\n"
    checks2_that_exist = map(basename, readdir(joinpath(dirname(@__DIR__), "checks2")))

    @testset for valfile in filter(f -> endswith(f, ".val"), readdir(@__DIR__))
        fname = valfile[1:end-4]
        in_file = fname * ".jl"
        checkname = replace(basename(fname), '_'=>'-')
        has_checks2 = basename(in_file) ∈ checks2_that_exist
        expected::String = normalize(read(valfile, String))
        args = ["--checks2", "--enable", checkname, "--", in_file]
        #println("Executing check $checkname, args: " * join(args, " "))
        result = IOCapture.capture() do
            JuliaCheck.main(args)
        end
        actual = normalize(result.output)
        if has_checks2
            actualfile::String = valfile * ".actual"
            if actual == expected
                if isfile(actualfile)
                    rm(actualfile)
                end
            else
                write(actualfile, actual)
            end
            @test actual == expected
        else
            println("Skipping $checkname because it does not exist yet")
            @test_skip actual == expected
        end 
    end
end

@run_package_tests
