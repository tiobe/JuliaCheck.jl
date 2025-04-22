function report_violation(loc, sf::SourceFile, problem::String, rule::String)
    line, column = JSx.source_location(sf, loc)
    printstyled("\n$problem at line $line, column $(column+1) of file '$(sf.filename)':\n";
                color=:yellow)
    # TODO Get the snippet (or the whole affected line) from JuliaSyntax
    opt1 = "-n"; opt2 = "$line p"; opt3 = "$(sf.filename)"
    run(`sed $opt1 $opt2 $opt3`)
    println(repeat(' ', column), '^')
    println(rule)
end

function report_violation(node::SyntaxNode, sf::SourceFile, problem::String, rule::String)
    line, column = JSx.source_location(node)
    printstyled("\n'$(sf.filename)', line $line, column $(column+1):\n"; underline=true)
    JSx.highlight(stdout, node; note=problem, notecolor=:yellow,
                                context_lines_after=0, context_lines_before=0)
    printstyled("\n$rule\n"; color=:cyan)
end
