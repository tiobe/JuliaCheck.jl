module IndentationLevelsAreFourSpaces

import JuliaSyntax: GreenNode, SourceFile, @K_str, kind, children, span
using ...Properties: lines_count, report_violation, source_index, sourcetext

function check(node::GreenNode)
    if kind(node) != K"NewlineWs"
        return nothing
    end
    textual = sourcetext(node)
    indentext = chomp(reverse(textual))
    # Tabs are flagged by another rule. To prevent double report, account for
    # their presence here, counting 4-1 extra spaces for each tab.
    indentation = length(indentext) + 3 * count(r"\t", indentext)
    if rem(indentation, 4) > 0
        report_violation(index=source_index()+1, len=indentation,
                         line=lines_count()+1, col=1,
                         severity=7, rule_id="asml-indentation-levels-are-four-spaces",
                         user_msg="Indentation here is $indentation, which is not multiple of 4.",
                         summary="Indentation will be done in multiples of four spaces.")
    end
end


end
