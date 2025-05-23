module ModuleEndComment

import JuliaSyntax: GreenNode, @K_str, children, kind
using ...Properties: haschildren, is_upper_camel_case, report_violation

function check(modjule::GreenNode, above::GreenNode)::Nothing
    @assert kind(modjule) == K"module" "Expected a [module] node, got [$(kind(node))]."
    pos = findfirst(x -> x === modjule, children(above))
    @assert pos !== nothing "This [module] node does not seem to be child of its parent!"
    # Is it child of Julio Iglesias or Jonathan M., then?
    very_last = last(children(above))
    if modjule !== very_last
        next = children(above)[pos + 1]
        if kind(next) == K"Whitespace" && next !== very_last
            next = children(above)[pos + 2]
        end
        if kind(next) == K"Comment" #&& matches_module_name()
            return nothing  # it's good!
        end
    end
    report_violation()
    return nothing
end

function matches_module_name(mod_name::String, comment::String)
    return occursin(Regex("(module[ ]+)?" * mod_name), comment)
end

end
