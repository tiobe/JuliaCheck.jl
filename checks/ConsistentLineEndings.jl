module ConsistentLineEndings

using JuliaSyntax: SourceFile, JuliaSyntax as JS
using ..Properties: is_toplevel

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "consistent-line-endings"
severity(::Check) = 7
synopsis(::Check) = "Make sure that the line endings are consistent within a file"


function init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_toplevel, n -> _check(this, ctxt, n))
    return nothing
end

struct LineEnding
    name::AbstractString
    pattern::Regex
end

"Line ending options we consider, the most common one present is seen as 'correct' for a file"
const LINE_END_OPTIONS = [
    LineEnding("CRLF", r"\r\n"),
    LineEnding("CR", r"\r[^\n]"),
    LineEnding("LF", r"[^\r]\n")
]

"""
Return true if the number of matches found for line ending `a` is less than those found for `b`.
Added this to be able to use `maximum(x::Vector{Tuple{LineEnding, Vector{RegexMatch}}})` below.
"""
function Base.isless(a::Tuple{LineEnding, Vector{RegexMatch}}, b::Tuple{LineEnding, Vector{RegexMatch}})
    return isless(length(a[2]), length(b[2]))
end

function _check(this::Check, ctxt::AnalysisContext, node::SyntaxNode)::Nothing
    matches = map(le -> (le, collect(eachmatch(le.pattern, node.source.code))), LINE_END_OPTIONS)
    most_common_le = maximum(matches)
    incorrect_newline_matches = filter(!=(most_common_le), matches)

    for newline_match in incorrect_newline_matches
        for match in newline_match[2]
            line = JS.source_line(node.source, match.offset)
            source_pos = JS.source_line_range(node.source, match.offset)
            report_violation(ctxt, this, (line, 0), source_pos[1]:source_pos[2], "Inconsistent line ending $(newline_match[1].name), should match rest of the file ($(most_common_le[1].name))")
        end
    end
    return nothing
end

end # module ConsistentLineEndings
