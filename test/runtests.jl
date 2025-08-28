using Test: @test #, @testset
using TestItems: @testitem
using TestItemRunner
using JuliaCheck

@testitem "Symbols Table tests" begin
    using JuliaSyntax: GreenNode, Kind, @K_str, SyntaxNode, parsestmt,
        JuliaSyntax as JS
    include("../src/Properties.jl")
    include("../src/SymbolTable.jl"); using .SymbolTable: is_declared_in_current_scope,
        clear_symbol_table!, declare!, enter_module!, enter_main_module!, enter_scope!,
        exit_module!, exit_main_module!, exit_scope!, is_declared, is_global

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

    # Push a new scope in Main module
    # State expectations:
    # Symbol Table State:
    #    Module stack (1 modules):
    #        [1] Module: Main <- current
    #            Scope stack (2 scopes):
    #                [1] Scope: {z, x} <- current
    #                [2] Scope (global): {y, x}
    enter_scope!()
    z = make_node("z")
    declare!(z)
    declare!(x)

    @test is_declared(x)
    @test is_declared(y)
    @test is_declared(z)
    @test ! is_declared(make_node("w"))
    @test is_global(x)  # This might not be valid in the future, since 'x' is shadowed
    @test is_global(y)
    @test ! is_global(z)

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

    enter_module!("MyModule")
    a = make_node("a")
    b = make_node("b")
    declare!(a)
    declare!(b)

    @test is_declared(a)
    @test is_declared(b)

    @test is_declared_in_current_scope(a)
    @test is_declared_in_current_scope(b)

    @test !is_declared_in_current_scope(x)
    @test !is_declared_in_current_scope(y)
    @test !is_declared_in_current_scope(z)

    @test is_global(a)
    @test is_global(b)

    # Pop module
    # State expectations:
    # Symbol Table State:
    #    Module stack (1 modules):
    #        [1] Module: Main <- current
    #            Scope stack (2 scopes):
    #                [1] Scope: {z, x} <- current
    #                [2] Scope (global): {y, x}

    exit_module!()
    @test !is_declared(a)
    @test !is_declared(b)
    @test is_declared_in_current_scope(x)
    @test is_declared(y)
    @test !is_declared_in_current_scope(y)
    @test is_declared_in_current_scope(z)

    # Pop scope in Main module, then exit the module itself.
    # State expectations:
    # Symbol Table State:
    #    Module stack (1 modules):
    #        [1] Module: Main <- current
    #            Scope stack (1 scopes):
    #                [1] Scope (global): {y, x} <- current

    exit_scope!()
    @test is_declared(x)
    @test is_declared(y)
    @test !is_declared(z)

    # Finally, exit the main module, and nothing should be declared here anymore.
    exit_main_module!()
    @test !is_declared(x)
    @test !is_declared(y)
end


@testitem "Numbers" begin
    using JuliaSyntax: SyntaxNode, parsestmt
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
    camel_to_kebab(s::String) = lowercase(replace(s, r"(?<!^)([A-Z])" => s"-\1"))
   
    all_checks = filter(f -> !startswith(f, "_"), map(basename, readdir(joinpath(dirname(@__DIR__), "checks2"))))

    @testset for checkfile in all_checks
        testfile = replace(checkfile, r"/checks2?/" => s"test")
        valfile = splitext(testfile)[1] * ".val"

        checkname = camel_to_kebab(splitext(basename(checkfile))[1])
        expected::String = normalize(read(valfile, String))
        args = ["--enable", checkname, "--", testfile]
        result = IOCapture.capture() do
            JuliaCheck.main(args)
        end
        actual = normalize(result.output)
        actualfile::String = valfile * ".actual"
        if actual == expected
            if isfile(actualfile)
                rm(actualfile)
            end
        else
            write(actualfile, actual)
        end
        @test actual == expected
    end
end

@testitem "JuliaCheck self" begin
    import IOCapture
    isjuliafile = f -> endswith(f, ".jl")
    checkfiles = filter(isjuliafile, readdir(joinpath(dirname(@__DIR__), "checks2"), join=true))
    srcfiles = filter(isjuliafile, readdir(joinpath(dirname(@__DIR__), "src"), join=true))
    files = union(checkfiles, srcfiles)

    println("Hallo")
    args = ["--"]
    for file in files[1:20]
        push!(args, file)
    end

    try 
        @test length(files) >= 1
        result = IOCapture.capture() do
            JuliaCheck.main(args)
        end
        out_file = joinpath(@__DIR__, "JuliaCheck-self.out")
        write(out_file, result.output)
        println("Finished analyzing $(length(files)) files. Wrote result to $out_file.")
    catch ex
        println(ex)
        @test false 
    end
end


@run_package_tests
