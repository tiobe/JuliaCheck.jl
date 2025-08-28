module ModuleEndComment

include("_common.jl")

using JuliaSyntax: last_byte
using ...Properties: is_module, is_toplevel, get_module_name

struct Check<:Analysis.Check end
id(::Check) = "module-end-comment"
severity(::Check) = 9
synopsis(::Check) = "The end statement of a module should have a comment with the module name"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_module, n -> checkModule2(this, ctxt, n))
end

function checkModule2(this::Check, ctxt::AnalysisContext, mod::SyntaxNode)
    code = mod.source.code
    mod_end = last_byte(mod)
    eol = something(findnext('\n', code, mod_end), length(code))
    comment_start = something(findnext('#', code, mod_end), length(code))
    if comment_start >= eol
        filepos = source_location(mod.source, mod_end)
        report_violation(ctxt, this, filepos, range(mod_end-2, length=3), "Missing end module comment")
    else 
        comment_range = comment_start:eol
        comment = code[comment_range]
        (_, mod_name_str) = get_module_name(mod)
        if !matches_module_name(mod_name_str, comment)
            filepos = source_location(mod.source, mod_end)
            report_violation(ctxt, this, filepos, comment_range, synopsis(this))
        end
    end
end

function matches_module_name(mod_name::AbstractString, comment::AbstractString)
    return occursin(Regex("(module[ ]+)?" * mod_name), comment)
end

end # module ModuleEndComment
