module UseSpacesInsteadOfTabs

import JuliaSyntax: GreenNode, SourceFile, @K_str, kind, children, sourcetext, span
using ...Properties: report_violation

function check(node::GreenNode, sf::SourceFile, index::Int)
    if kind(node) != K"NewlineWs"
        return nothing
    end
    len = span(node)
    textual = sourcetext(sf)[index : index + len - 1]
    if occursin("\t", textual)
        report_violation(node; severity=7,
                rule_id="asml-xxxx-use-spaces-instead-of-tabs",
                user_msg="Use spaces instead of tabs for indentation.",
                summary="Use spaces instead of tabs for indentation.")
    end
end


end
