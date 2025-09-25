using Test: @test #, @testset
using TestItems: @testitem
using TestItemRunner
using JuliaCheck

@testitem "Symbols Table tests" begin
    using JuliaSyntax: GreenNode, Kind, @K_str, SyntaxNode, parsestmt,
        JuliaSyntax as JS
    include("../src/Properties.jl")
    include("../src/TypeHelpers.jl")
    include("../src/SymbolTable.jl"); using .SymbolTable: is_declared_in_current_scope,
        clear_symbol_table!, _declare!, enter_module!, enter_main_module!, enter_scope!,
        exit_module!, exit_main_module!, exit_scope!, is_declared, is_global, SymbolTableStruct

    make_node(input::String)::SyntaxNode = parsestmt(SyntaxNode, input)

    # Ensure we always start from a clean symbol table.
    # If run multiple times, contents of the symbol table are not as expected.
    table = SymbolTableStruct()

    # Add some identifiers to Main module, global scope
    enter_main_module!(table)
    x = make_node("x")
    y = make_node("y")
    _declare!(table, x)
    _declare!(table, y)

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
    _declare!(table, z)
    _declare!(table, x)

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
    _declare!(table, a)
    _declare!(table, b)

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
    include("../src/Properties.jl"); using .Properties: get_number

    make_node(input::String)::SyntaxNode = parsestmt(SyntaxNode, input)
    @test get_number(make_node("4.493_775_893_684_088e16")) == 4.493775893684088e16
end

@testitem "Golden File Tests" begin
    import IOCapture

    function get_test_files(checkfile_name::AbstractString)::Vector{String}
        if isdir(checkfile_name)
            files = map(relpath -> joinpath(checkfile_name, relpath), filter(endswith(".jl"), [f for (_, _, fs) in walkdir(checkfile_name) for f in fs]))
            return files
        else
            return [checkfile_name]
        end
    end

    normalize(text) = strip(replace(replace(text, "\r\n" => "\n", "\\" => "/"))) * "\n"
    camel_to_kebab(s::String) = lowercase(replace(s, r"(?<!^)([A-Z])" => s"-\1"))

    all_checks = filter(f -> !startswith(f, "_"), map(basename, readdir(joinpath(dirname(@__DIR__), "checks"))))

    # cd into res so that '>> Processing file 'SingleModuleFile.jl'...' does not change to
    # '>> Processing file 'res/SingleModuleFile.jl'...'
    cd("res") do
        @testset for check in all_checks
            testfiles = get_test_files(basename(check))
            @testset for testfile in testfiles
                valfile = splitext(testfile)[1] * ".val"

                if !isfile(valfile)
                    throw("Missing .val file: $valfile")
                end
                checkname = camel_to_kebab(splitext(basename(check))[1])
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
    end
end

@testitem "JuliaCheck self" begin
    import IOCapture
    isjuliafile = f -> endswith(f, ".jl")
    checkfiles = filter(isjuliafile, readdir(joinpath(dirname(@__DIR__), "checks"), join=true))
    srcfiles = filter(isjuliafile, readdir(joinpath(dirname(@__DIR__), "src"), join=true))
    files = union(checkfiles, srcfiles)

    args = ["--"]
    for file in files
        push!(args, file)
    end

    @test length(files) >= 1
    result = IOCapture.capture() do
        JuliaCheck.main(args)
    end
    out_file = joinpath(@__DIR__, "JuliaCheck-self.out")
    write(out_file, result.output)
    println("Finished analyzing $(length(files)) files. Wrote result to $out_file.")
end


@run_package_tests
