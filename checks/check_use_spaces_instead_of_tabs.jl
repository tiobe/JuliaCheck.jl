module UseSpacesInsteadOfTabs

import JuliaSyntax: GreenNode, SourceFile, @K_str, kind, children, span
using ...Properties: lines_count, report_violation, source_index, sourcetext

function check(node::GreenNode)
    if kind(node) != K"NewlineWs"
        return nothing
    end
    len = span(node)
    textual = sourcetext(node)
    match = findfirst("\t", textual)
    if match !== nothing
        pos = match.start
        text_before = textual[1:pos-1]
        line = lines_count() + count(r"\n", text_before)
        col = pos - findlast("\n", text_before).start
        report_violation(index=source_index()+pos-1, len=1, line=line, col=col,
                         severity=7, rule_id="asml-xxxx-use-spaces-instead-of-tabs",
                         user_msg="Use spaces instead of tabs for indentation.",
                         summary="Use spaces instead of tabs for indentation.")
    end
end


end
