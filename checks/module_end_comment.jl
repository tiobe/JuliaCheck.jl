module ModuleEndComment

import JuliaSyntax: SyntaxNode, GreenNode, @K_str, children, kind,
        first_byte, last_byte, span
using ...Checks: is_enabled
using ...Properties: find_lhs_of_kind, haschildren, is_upper_camel_case,
        get_module_name, lines_count, report_violation, source_column,
        source_index, source_text

const SEVERITY = 9
const RULE_ID = "module-end-comment"
const USER_MSG = "The end statement of module has a comment with the module name."
const SUMMARY = "The \"end\" of a module quotes the module name in a comment."

# FIXME: those node equality comparisons don't work, so this check is
# very unreliable.

function check(modjule::SyntaxNode)::Nothing
    if !is_enabled(RULE_ID) return nothing end

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
            comment = source_text(comment_index, span(next))
            if matches_module_name(mod_name_str, comment)
                return nothing  # it's good!
            end
        end
    end
    # Either no comment found, or not in the same line as the [end] (that is
    # not considered OK), or the comment didn't match the expected content.
    report_violation(mod_name_node; severity = SEVERITY, rule_id = RULE_ID,
                                    user_msg = USER_MSG, summary = SUMMARY)
    # TODO report on the 'end' keyword, not on the 'module'.
end

function matches_module_name(mod_name::AbstractString, comment::AbstractString)
    return occursin(Regex("(module[ ]+)?" * mod_name), comment)
end

end
