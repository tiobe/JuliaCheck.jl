module StructMembersAreInLowerSnakeCase

include("_common.jl")

using ...Properties: find_lhs_of_kind, is_lower_snake, get_struct_members

struct Check<:Analysis.Check end
Analysis.id(::Check) = "struct-members-are-in-lower-snake-case"
Analysis.severity(::Check) = 8
Analysis.synopsis(::Check) = "Struct members should be in \"lower_snake_case\"."

function Analysis.init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) === K"struct", node -> begin
        for field in get_struct_members(node)
            _check(this, ctxt, field)
        end
    end)
end

function _check(this::Check, ctxt::AnalysisContext, field::SyntaxNode)
    @assert kind(field.parent) == K"block" &&
            kind(field.parent.parent) == K"struct"  "Expected a node representing" *
                        " a field (child of a [struct])" field.parent
    if kind(field) == K"function"
        # This is not a field really, but an inner constructor (a function
        # inside a type definition), which must match the type's name, which
        # must follow a different naming convention than functions do.
        return nothing
    end
    field_name = find_lhs_of_kind(K"Identifier", field)
    if !is_lower_snake(string(field_name))
        report_violation(ctxt, this, field_name, "Field '$field_name' not in \"lower_snake_case\"")
    end
end

end # module StructMembersAreInLowerSnakeCase
