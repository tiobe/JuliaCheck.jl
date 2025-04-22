
## Globals ##
LOC::Int = 0


reset_token_index() = global LOC = 0
bump_token_index(node::Node) = global LOC += length(JSx.char_range(node)) #JSx.span(node)


function check(file_name::String)
    sf = SourceFile(; filename=file_name)
    process(parse(sf), sf)
end

function parse(sf::SourceFile)
    return  try JSx.parseall(Node, JSx.sourcetext(sf); ignore_trivia=false)
            catch xspt
                if xspt isa ParseError
                    foreach(dg->println(dg), xspt.diagnostics)
                else
                    println(xspt)
                end
                nothing
            end
end

function process(_::Nothing, sf::SourceFile)
    @error "Couldn't parse file '$(sf.filename)'"
end

function process(ast::Node, sf::SourceFile)
    @assert is_toplevel(ast)
    "This method applies only to the top-level node of the AST, i.e., pass "*
    "the result of a parseall call on the whole file text."
    @debug "\n" * sprint(show, MIME("text/plain"), ast) #, JSx.sourcetext(sf))
    reset_token_index()
    enter_module(ast)    # There is always at least Main's global scope
    process(ast, ast, sf)
end

function process(node::Node, parent::Node, sf::SourceFile)
    if !(JSx.haschildren(node))
        bump_token_index(node)
        if closes_module(node, parent)
            exit_module()
        elseif closes_scope(node, parent)
            exit_scope()
            # TODO do this with scope being a mutable struct with a finalizer to
            # pop the scope set off the SymbolsTable stack when the struct object
            # goes out of scope.
        end

    else
        if is_module(node)
            enter_module(node)

        elseif is_op_call(node)
            process_operator(node, parent, sf)

        elseif is_function(node)
            process_function(node, parent, sf)

        #elseif is_body(node)
        end

        foreach(x -> process(x, node, sf), children(node))
    end
end

function process_operator(node::Node, parent::Node, sf::SourceFile)
    if JSx.is_prefix_op_call(node)
        # something with prefix operators

    elseif is_infix_operator(node)
        space_around_infix_operators(node, parent, sf)     # check
        # FIXME rewrite with SyntaxNode instead of GreenNode

        if is_assignment(node)
            process_assignment(node, parent, sf)
        end

    elseif JSx.is_postfix_op_call(node)
        # something with postfix operators
    end
end

function process_function(node::Node, parent::Node, sf::SourceFile)
    declare(get_func_name(node))
    enter_scope()
    foreach(declare, get_func_arguments(node))
end

function process_assignment(node::Node, parent::Node, sf::SourceFile)
    lhs = get_assignee(node)
    if !is_declared(lhs)
        declare(lhs)
    end
    avoid_globals(node, parent, sf)     # check
end
