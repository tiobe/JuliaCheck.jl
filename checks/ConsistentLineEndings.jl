module ConsistentLineEndings

include("_common.jl")

using JuliaSyntax: SourceFile, JuliaSyntax as JS
using ..Properties: is_toplevel

struct Check<:Analysis.Check end
id(::Check) = "consistent-line-endings"
severity(::Check) = 3
synopsis(::Check) = "Use consistent line endings"


function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_toplevel, n -> _check(this, ctxt, n))
end

struct LineEnding
    name::AbstractString
    pattern::Regex
end

const LINE_END_OPTIONS = [
    LineEnding("CRLF", r"\r\n"),
    LineEnding("CR", r"\r[^\n]"),
    LineEnding("LF", r"[^\r]\n")
]

function Base.isless(a::Tuple{LineEnding,Vector{RegexMatch}}, b::Tuple{LineEnding,Vector{RegexMatch}})
    return isless(length(a[2]), length(b[2]))
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    matches = map(le -> (le, collect(eachmatch(le.pattern, node.source.code))), LINE_END_OPTIONS)
    most_common_le = maximum(matches)
    incorrect_les = filter(!=(most_common_le), matches)

    for le in incorrect_les
        for match in le[2]
            line = JS.source_line(node.source, match.offset)
            source_pos = JS.source_line_range(node.source, match.offset)
            report_violation(ctxt, this, (line, 0), source_pos[1]:source_pos[2], "Inconsistent line ending $(le[1].name), should match rest of the file ($(most_common_le[1].name))")
        end
    end
end

end # module ConsistentLineEndings
