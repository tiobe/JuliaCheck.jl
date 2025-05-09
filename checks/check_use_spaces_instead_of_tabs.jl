module UseSpacesInsteadOfTabs

import JuliaSyntax: GreenNode, @K_str, kind, children, sourcetext, untokenize
using ...Properties: report_violation

function check(node::GreenNode)
    if kind(node) != K"NewlineWs"
        return nothing
    end
    textual = untokenize(node)
    if occursin("\t", textual)
        report_violation(f_arg; severity=7,
                rule_id="",
                user_msg="",
                summary="")
    end
end


end
