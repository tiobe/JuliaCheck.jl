module ModuleEndComment

include("_common.jl")

using JuliaSyntax: last_byte
using ...Properties: is_module, is_toplevel, get_module_name

struct Check<:Analysis.Check end
Analysis.id(::Check) = "module-end-comment"
Analysis.severity(::Check) = 9
function Analysis.synopsis(::Check)
    return "The end statement of a module should have a comment with the module name"
end

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_module, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, mod::SyntaxNode)::Nothing
    code = mod.source.code
    mod_end = last_byte(mod)
    eol = something(findnext('\n', code, mod_end), length(code))
    comment_start = something(findnext('#', code, mod_end), length(code))
    if comment_start >= eol
        filepos = source_location(mod.source, mod_end)
        report_violation(ctxt, this, filepos, range(mod_end - 2; length=3), "Missing end module comment")
    else
        comment_range = comment_start:eol
        comment = code[comment_range]
        (_, mod_name_str) = get_module_name(mod)
        if !_matches_module_name(mod_name_str, comment)
            filepos = source_location(mod.source, mod_end)
            report_violation(ctxt, this, filepos, comment_range, synopsis(this))
        end
    end
    return nothing
end

function _matches_module_name(mod_name::AbstractString, comment::AbstractString)::Bool
    return occursin(Regex("(module[ ]+)?" * mod_name), comment)
end

end # module ModuleEndComment
