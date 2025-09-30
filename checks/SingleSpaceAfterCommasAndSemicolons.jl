module SingleSpaceAfterCommasAndSemicolons

include("_common.jl")

using ...Properties: is_toplevel
using ...SyntaxNodeHelpers

struct Check<:Analysis.Check end
id(::Check) = "single-space-after-commas-and-semicolons"
severity(::Check) = 7
synopsis(::Check) = "Commas and semicolons are followed, but not preceded, by a space."

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, is_toplevel, node -> begin
        code = node.source.code
        report_if_space(pos::Integer, func::Function, shouldhave::Integer, msg::String) = begin
            range = func(code, pos)
            if length(range) != shouldhave && !contains(code[range], '\n') # skip check if range contains a newline
                report_violation(ctxt, this, 
                    source_location(node.source, range.start), 
                    range,
                    msg
                    )
            end
        end
        for m in eachmatch(r"[;,]", code) # Find each occurrence in code
            pos = m.offset
            leaf = find_greenleaf(ctxt, pos) # Find the GreenLeaf containing the character
            if kind(leaf.node) ∉ KSet"Char Comment String" # Skip strings and comments
                report_if_space(pos, find_whitespace_func(false), 0, "Unexpected whitespace")
                report_if_space(pos, find_whitespace_func(true), 1, "Expected single whitespace")
            end
        end
    end)
end

function find_whitespace_func(forward::Bool)::Function
    find = forward ? nextind : prevind
    return (s::AbstractString, start::Integer) -> begin
        p = find(s, start)
        first_find = p
        last_find = nothing
        while p >= firstindex(s) && p <= lastindex(s) && isspace(s[p])
            last_find = p
            p = find(s, p)
        end
        if isnothing(last_find)
            return range(first_find, length=0)
        elseif forward
            return first_find:last_find
        else # backward
            return last_find:first_find
        end
    end
end

end # module SingleSpaceAfterCommasAndSemicolons
