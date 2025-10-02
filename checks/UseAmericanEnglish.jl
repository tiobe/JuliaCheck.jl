module UseAmericanEnglish

using ...CommentHelpers: contains_comments, get_comments, get_range, get_text
using JuliaSyntax: byte_range, GreenNode, SyntaxNode

include("_common.jl")

struct Check<:Analysis.Check end
id(::Check) = "use-american-english"
severity(::Check) = 9
synopsis(::Check) = "Comments should be in the American-English language"

function init(this::Check, ctxt::AnalysisContext)::Nothing
    forbidden_words = _load_words(joinpath(@__DIR__, "_config", "words_en-GB.txt"))
    register_syntaxnode_action(ctxt, contains_comments, n -> _check_comment(this, ctxt, n, forbidden_words))
    register_syntaxnode_action(ctxt, n -> kind(n) == K"doc", n -> _check_docstring(this, ctxt, n, forbidden_words))
    return nothing
end

function _load_words(path::String)::Vector{AbstractString}
    include_dependency(path)
    return open(path) do f
        return readlines(f)
    end
end

function _check_docstring(this::Check, ctxt::AnalysisContext, node::SyntaxNode, forbidden_words::Vector{AbstractString})::Nothing
    string_node = children(node)[1]
    text = sourcetext(string_node)
    _check_for_british_spellings(this, ctxt, forbidden_words, text, byte_range(node))
    return nothing
end

function _check_comment(this::Check, ctxt::AnalysisContext, node::SyntaxNode, forbidden_words::Vector{AbstractString})::Nothing
    comments = get_comments(node)
    for c in comments
        _check_for_british_spellings(this, ctxt, forbidden_words, get_text(c), get_range(c))
    end
    return nothing
end

function _check_for_british_spellings(this::Check, ctxt::AnalysisContext, forbidden_words::Vector{AbstractString}, text::AbstractString, range::UnitRange)::Nothing
    forbidden_words_in_text = _contained_words_from(forbidden_words, text)
    if !isempty(forbidden_words_in_text)
        report_violation(ctxt, this, range, "Text contains British spelling: $(join(forbidden_words_in_text, ", ")).")
    end
    return nothing
end

function _contained_words_from(forbidden_words::Vector{AbstractString}, text::AbstractString)::Vector{AbstractString}
    words = map(m -> m.match, eachmatch(r"\w+", lowercase(text)))
    return filter(in(words), forbidden_words)
end

end # module UseAmericanEnglish
