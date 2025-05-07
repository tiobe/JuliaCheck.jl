module Process

import JuliaSyntax: SourceFile, SyntaxNode, ParseError, @K_str, children, haschildren,
    kind, untokenize, JuliaSyntax as JS

# include("SymbolTable.jl")
# import .SymbolTable

include("Properties.jl")
using .Properties

include("Checks.jl")
import .Checks

export check


function check(file_name::String)
    sf = SourceFile(; filename=file_name)
    ast = parse(sf)
    if isnothing(ast)
        @error "Couldn't parse file '$file_name'"
    else
        @debug "Full AST for the file:" ast
        # @debug "\n" * sprint(show, MIME"text/plain"(), ast.raw, string(JS.sourcetext(sf)))
        # TODO Perhaps, printing the GreenNode tree should be an explicit separate option.
        process(ast)
        #SymbolTable.exit_module()   # leave `Main`
    end
end

function parse(sf::SourceFile)
    return  try JS.parseall(SyntaxNode, JS.sourcetext(sf);
                            filename=sf.filename, ignore_trivia=false)
            catch xspt
                if xspt isa ParseError
                    foreach(dg->println(dg), xspt.diagnostics)
                else
                    println(xspt)
                end
                nothing
            end
end


function process(node::SyntaxNode)
    if JS.haschildren(node)
        if is_toplevel(node)
            #SymbolTable.enter_module()  # There is always the `Main` module
            # TODO: a file can be `include`d into another, thus into another
            # module and, what is most important from the point of view of the
            # symbols table and declarations: something can be declared outside
            # the file under analysis, and we will surely get confused about its
            # scope.

        elseif is_module(node)
            #SymbolTable.enter_module(node)
            Checks.SingleModuleFile.check(node)
            Checks.ModuleNameCasing.check(node)

        elseif is_operator(node)
            process_operator(node)

        elseif is_function(node)
            process_function(node)

        elseif is_struct(node)
            process_struct(node)

        # elseif is_doc(node)
            # process_docstrings(node)

        #elseif is_body(node)
        end

        for x in children(node) process(x) end
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
    fname = get_func_name(node)
    if isnothing(fname)
        # There is nothing left to check, except the debug logging output, where
        # we might see a clue of what we are dealing with.
        return nothing
    end
    Checks.FunctionIdentifiersCasing.check(fname)
    #SymbolTable.declare(fname)
    #SymbolTable.enter_scope()
    named_arguments = []
    for arg in get_func_arguments(node)
        if kind(arg) == K"parameters" && haschildren(arg)
            # The last argument in the list is itself a list, of named arguments,
            # which we are going to process next.
            named_arguments = children(arg)
        else
            # SymbolTable.declare(arg)
            Checks.FunctionArgumentsCasing.check(fname, arg)
        end
    end
    for arg in named_arguments
        Checks.FunctionArgumentsCasing.check(fname, arg)
    end
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

function process_struct(node::SyntaxNode)
    # struct_name = get_struct_name(node)
    foreach(Checks.StructMembersCasing.check, get_struct_members(node))
end

end
