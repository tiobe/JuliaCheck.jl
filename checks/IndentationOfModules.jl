module IndentationOfModules

include("_common.jl")

using JuliaSyntax: view
using ...Properties: is_module, get_module_name
using ...SyntaxNodeHelpers: ancestors
using ...WhitespaceHelpers: normalized_green_child_range

struct Check<:Analysis.Check end
Analysis.id(::Check) = "indentation-of-modules"
Analysis.severity(::Check) = 7
Analysis.synopsis(::Check) = "Do not indent top level module body, do indent submodules"

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_module, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, module_node::SyntaxNode)::Nothing
    module_nest_level = count(is_module, ancestors(module_node; include_self=false))
    exp_indent = 4 * module_nest_level
    (_, module_name) = get_module_name(module_node)

    mod_contents_node = children(module_node)[2]
    for content_node in children(mod_contents_node)
        green_children = children(mod_contents_node.raw)
        green_node = content_node.raw
        green_idx = first(indexin([green_node], green_children))

        prev_i = prevind(green_children, green_idx)
        prev_sibling = checkbounds(Bool, green_children, prev_i) ? green_children[prev_i] : nothing

        if !isnothing(prev_sibling) && kind(prev_sibling) == K"NewlineWs" # Previous node is indent
            ws_range = normalized_green_child_range(mod_contents_node, prev_i)
            actual_indent = length(strip(view(module_node.source, ws_range), ['\r', '\n'])) # Only report on indent on current line (not newlines)

            if exp_indent != actual_indent
                nudged_range = range(;stop=ws_range.stop, length=actual_indent)
                report_violation(ctxt, this, nudged_range, "Contents of module '$module_name' should have an indentation of width $exp_indent, but found $actual_indent")
            end
        end
    end
end

end # module IndentationOfModules
