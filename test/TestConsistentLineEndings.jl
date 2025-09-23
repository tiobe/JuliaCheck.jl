#=
This test is separate from the goldenfile tests because it uses in-code strings as input
instead of files. The reason for this is to more easily insert non-standard line endings and
prevent these from being auto-converted out by e.g. Git or VSCode.

The line endings of this file itself should always be LF, see .gitattributes
=#
@testitem "ConsistentLineEndings.jl" begin
    include("../src/Properties.jl")
    include("../src/SymbolTable.jl")
    include("../src/Analysis.jl")
    using .Analysis
    include("../src/ViolationPrinters.jl")
    using .ViolationPrinters
    using JuliaSyntax: SourceFile
    include("../checks/ConsistentLineEndings.jl")
    using .ConsistentLineEndings: Check
    using IOCapture

    function test(text::AbstractString, exp::AbstractString)::Nothing
        checks::Vector{Analysis.Check} = [Check()]
        source = SourceFile(text; filename="test_file.jl")
        result = IOCapture.capture() do
            Analysis.run_analysis(source, checks, violationprinter=highlighting_violation_printer)
        end
        @test replace(result.output, r"\r\n?" => "\n") == exp   # In the output, we do not need to compare line endings
        return nothing
    end

    test_cases = [
        """
        module ConsistentLineEndings

        using JuliaSyntax: SourceFile

        function init(this::Check, ctxt::AnalysisContext) # This is a CRLF:\r\nregister_syntaxnode_action(ctxt, is_toplevel, n -> check(this, ctxt, n))
        end

        function _check(this::Check, ctxt::AnalysisContext, n::SyntaxNode)
            println("Doing the thing")
        end # This is a CR:\rend # module ConsistentLineEndings

        end # module ConsistentLineEndings
        """ => """

        test_file.jl(5, 0):
        function init(this::Check, ctxt::AnalysisContext) # This is a CRLF:
        └─────────────────────────────────────────────────────────────────┘ ── Inconsistent line ending CRLF, should match rest of the file (LF).
        Use consistent line endings.
        Rule: consistent-line-endings. Severity: 3

        test_file.jl(11, 0):
        end # This is a CR:
        end # module ConsistentLineEndings
        └───────────────────────────────────────────────────┘ ── Inconsistent line ending CR, should match rest of the file (LF).
        Use consistent line endings.
        Rule: consistent-line-endings. Severity: 3
        """,
        """
        module ConsistentLineEndings\r
\r
        using JuliaSyntax: SourceFile\r
\r
        function init(this::Check, ctxt::AnalysisContext) # This is an LF:
            register_syntaxnode_action(ctxt, is_toplevel, n -> check(this, ctxt, n))\r
        end\r
\r
        function _check(this::Check, ctxt::AnalysisContext, n::SyntaxNode)\r
            println("Doing the thing")\r
        end # This is a CR:\rend # module ConsistentLineEndings\r
\r
        end # module ConsistentLineEndings\r
        """ => """

        test_file.jl(11, 0):
                end # This is a CR:
        end # module ConsistentLineEndings
        └───────────────────────────────────────────────────────────┘ ── Inconsistent line ending CR, should match rest of the file (CRLF).
        Use consistent line endings.
        Rule: consistent-line-endings. Severity: 3

        test_file.jl(5, 0):
                function init(this::Check, ctxt::AnalysisContext) # This is an LF:
        └────────────────────────────────────────────────────────────────────────┘ ── Inconsistent line ending LF, should match rest of the file (CRLF).
        Use consistent line endings.
        Rule: consistent-line-endings. Severity: 3
        """
    ]

    for (text, exp) in test_cases
        test(text, exp)
    end
end
