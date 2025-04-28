module Process

import JuliaSyntax as JS
using JuliaSyntax: SourceFile, SyntaxNode, ParseError, children

using ..JuliaCheck: display, to_string

include("SymbolTable.jl")
import .SymbolTable: declare, enter_module, exit_module, is_declared

include("Properties.jl")
import .Properties: closes_module, closes_scope, is_assignment, is_function,
    is_infix_operator, is_module, is_operator, is_toplevel, get_assignee,
    get_func_arguments, get_func_name

include("Checks.jl")
import .Checks

export check


function check(file_name::String)
    sf = SourceFile(; filename=file_name)
    process(parse(sf), file_name)
    exit_module()   # leave `Main`
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
            enter_module()  # There is always the `Main` module
            # TODO: a file can be `include`d into another, thus into another
            # module, which is most important from the point of view of the
            # symbols table and declarations: something can be declared outside
            # the file under analysis, and we will surely get confused about its
            # scope.

        elseif is_module(node)
            enter_module(node)

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
            exit_module(node.parent)
        elseif closes_scope(node)
            exit_scope()
        end
    end
end

function process_operator(node::SyntaxNode)
    if JS.is_prefix_op_call(node)
        # something with prefix operators

    elseif is_infix_operator(node)
        Checks.SpaceAroundInfixOperators.check(node)

        if is_assignment(node)
            process_assignment(node)
        end

    elseif JS.is_postfix_op_call(node)
        # something with postfix operators
    end
end

function process_function(node::SyntaxNode)
    declare(get_func_name(node))
    enter_scope()
    foreach(declare, get_func_arguments(node))
end

function process_assignment(node::SyntaxNode)
    lhs = get_assignee(node)
    if !is_declared(lhs)
        declare(lhs)
    end
    Checks.AvoidGlobals.check(node)
end

end
