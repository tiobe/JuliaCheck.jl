module ModuleEndComment

include("_common.jl")

using JuliaSyntax: first_byte, last_byte, sourcetext, span, source_location
using ...Properties: is_module, is_toplevel, get_module_name

struct Check <: Analysis.Check end
id(::Check) = "module-end-comment"
severity(::Check) = 9
synopsis(::Check) = "The end statement of a module should have a comment with the module name."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_module, n -> checkModule2(this, ctxt, n))
end

# FIXME: those node equality comparisons don't work, so this check is
# very unreliable.

function checkModule(this::Check, ctxt::AnalysisContext, modjule::SyntaxNode)
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(modjule))]."
    above = modjule.parent.raw
    pos = findfirst(x -> x === modjule.raw, children(above))
    @assert pos !== nothing "This [module] node does not seem to be child of its parent!"
    # Whose child is it, then? Julio Iglesias? Jonathan M.?

    (mod_name_node, mod_name_str) = get_module_name(modjule)
    if pos < length(children(above))
        comment_index = last_byte(modjule) + 1
        next = children(above)[pos + 1]
        if kind(next) == K"Whitespace" && pos + 1 < length(children(above))
            comment_index += span(next)
            next = children(above)[pos + 2]
        end
        if kind(next) == K"Comment"
            comment = ctxt.sourcecode[comment_index:span(next)]
            if matches_module_name(mod_name_str, comment)
                return nothing  # it's good!
            end
        end
    end
    # Either no comment found, or not in the same line as the [end] (that is
    # not considered OK), or the comment didn't match the expected content.
    report_violation(ctxt, this, modjule, synopsis(this))
    # TODO report on the 'end' keyword, not on the 'module'.
end

function checkModule2(this::Check, ctxt::AnalysisContext, mod::SyntaxNode)

    mod_end = last_byte(mod)
    eol = something(findnext('\n', ctxt.sourcecode, mod_end), length(ctxt.sourcecode))
    comment_start = something(findnext('#', ctxt.sourcecode, mod_end), length(ctxt.sourcecode))
    if comment_start >= eol
        report_violation(ctxt, this, mod, "Missing end module comment")
    else 
        comment = ctxt.sourcecode[comment_start:eol]
        (_, mod_name_str) = get_module_name(mod)
        if !matches_module_name(mod_name_str, comment)
            report_violation(ctxt, this, mod, synopsis(this))
        end
    end
end


function matches_module_name(mod_name::AbstractString, comment::AbstractString)
    return occursin(Regex("(module[ ]+)?" * mod_name), comment)
end

end
