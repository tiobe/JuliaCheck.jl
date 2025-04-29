module Process

import JuliaSyntax: SourceFile, SyntaxNode, ParseError, @K_str, children, kind,
    untokenize, JuliaSyntax as JS

# include("SymbolTable.jl")
# import .SymbolTable

include("Properties.jl")
using .Properties

include("Checks.jl")
import .Checks

include("Utils.jl")
import .Utils: to_string

export check


function check(file_name::String)
    sf = SourceFile(; filename=file_name)
    process(parse(sf), file_name)
    #SymbolTable.exit_module()   # leave `Main`
end

function parse(sf::SourceFile)
    return  try JS.parseall(SyntaxNode, JS.sourcetext(sf); ignore_trivia=false)
            catch xspt
                if xspt isa ParseError
                    foreach(dg->println(dg), xspt.diagnostics)
                else
                    println(xspt)
                end
                nothing
            end
end

function process(_::Nothing, file_name::String)
    @error "Couldn't parse file '$file_name'"
end

function process(node::SyntaxNode, file_name::String)
    if JS.haschildren(node)
        if is_toplevel(node)
            @debug "\n" * to_string(node)     # Print the AST
            # @debug "\n" * to_string(node.raw) # print the Green-tree
            #SymbolTable.enter_module()  # There is always the `Main` module
            # TODO: a file can be `include`d into another, thus into another
            # module and, what is most important from the point of view of the
            # symbols table and declarations: something can be declared outside
            # the file under analysis, and we will surely get confused about its
            # scope.

        elseif is_module(node)
            #SymbolTable.enter_module(node)

        elseif is_operator(node)
            process_operator(node)

        elseif is_function(node)
            process_function(node)

        # elseif is_doc(node)
            # process_docstrings(node)

        #elseif is_body(node)
        end

        foreach(x -> process(x, file_name), children(node))
        # guajes = children(node)
        # for guaje in guajes
        #     process(guaje, file_name)
        # end
    else
        if closes_module(node)
            #SymbolTable.exit_module(node.parent)
        elseif closes_scope(node)
            #SymbolTable.exit_scope()
        elseif is_literal(node)
            process_literal(node)
        end
    end
end

function process_operator(node::SyntaxNode)
    if JS.is_prefix_op_call(node)
        # something with prefix operators

    elseif is_infix_operator(node)
        #Checks.SpaceAroundInfixOperators.check(node)

        if is_assignment(node)
            process_assignment(node)
        end

    elseif JS.is_postfix_op_call(node)
        # something with postfix operators
    end
end

function process_function(node::SyntaxNode)
    #SymbolTable.declare(get_func_name(node))
    #SymbolTable.enter_scope()
    #foreach(SymbolTable.declare, get_func_arguments(node))
end

function process_assignment(node::SyntaxNode)
    lhs = get_assignee(node)
    # if !SymbolTable.is_declared(lhs)
    #     SymbolTable.declare(lhs)
    # end
    # Checks.AvoidGlobals.check(node)
end

function process_literal(node::SyntaxNode)
    if     (kind(node) == K"Integer")
    elseif (kind(node) == K"Float")
        Checks.LeadingAndTrailingDigits.check(node)
    end
end

end
