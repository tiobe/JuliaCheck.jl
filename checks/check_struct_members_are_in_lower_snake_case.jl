module StructMembersCasing

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Properties: find_first_of_kind, is_lower_snake, report_violation

function check(field::SyntaxNode)
    @assert kind(field.parent) == K"block" &&
            kind(field.parent.parent) == K"struct"  "Expected a node representing" *
                        " a field (child of a [struct])" field.parent
    field_name = find_first_of_kind(K"Identifier", field)
    if !is_lower_snake(string(field_name))
        report_violation(field_name; severity=8, rule_id="struct_members_are_in_lower_snake_case",
                user_msg="'struct' members are implemented in \"lower_snake_case\".",
                summary="Members of 'struct's are defined in \"lower_snake_case\".")
    end
end


end
