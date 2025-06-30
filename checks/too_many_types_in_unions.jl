module TooManyTypesInUnions

import JuliaSyntax: SyntaxNode, @K_str, kind, children
using ...Checks: is_enabled
using ...Properties: is_union_decl, report_violation

const SEVERITY = 6
const RULE_ID = "asml-too-many-types-in-unions"
const USER_MSG = "Union has too many types."
const SUMMARY = "Too many types in Unions."

function check(union_decl::SyntaxNode)
    if !is_enabled(RULE_ID) return nothing end

    @assert is_union_decl(union_decl) "Expected a Union declaration, got $(kind(union_decl))"
    union_types = children(union_decl)[2:end] # discard the 1st, which is "Union"
    if length(union_types) > 4
        report_violation(union_decl; severity = SEVERITY, rule_id = RULE_ID,
                                     user_msg = USER_MSG, summary = SUMMARY)
    end
end

end
