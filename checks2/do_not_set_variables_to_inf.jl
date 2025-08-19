module DoNotSetVariablesToInf

include("_common.jl")

import JuliaSyntax: span, untokenize
using ...Properties: find_lhs_of_kind, get_assignee, haschildren

struct Check <: Analysis.Check end
id(::Check) = "do-not-set-variables-to-inf"
severity(::Check) = 3
synopsis(::Check) = "Do not set variables to Inf, Inf16, Inf32 or Inf64"

function init(this::Check, ctxt::AnalysisContext)
    register_syntaxnode_action(ctxt, n -> kind(n) == K"=", n -> checkAssignment(this, ctxt, n))
end

"""
    check(node::SyntaxNode)

Check if a node contains assignments of Inf values to variables.
"""
function checkAssignment(this::Check, ctxt::AnalysisContext, node::SyntaxNode)
    @assert kind(node) == K"=" "Expected an assignment [=] node, got $(kind(node))."
    # Assignment should have exactly 2 children: lhs and rhs

    if length(children(node)) != 2
        @debug "Assignment with $(length(children(node))) children instead of 2."
        return nothing
    end
    rhs = children(node)[2]
    # Check if right-hand side is an Inf value
    if is_inf_value(rhs)
        report_violation(ctxt, this, rhs, synopsis(this))
    end
end


function is_inf_value(node::SyntaxNode)::Bool
    Infs = ("Inf", "Inf16", "Inf32", "Inf64")

    # Check if it's an identifier
    if kind(node) == K"Identifier"
        identifier_text = string(node)
        return identifier_text in Infs
    end
    
    # Check if it's a qualified name like Base.Inf
    if kind(node) == K"."
        if length(children(node)) >= 2
            # Get the last part of the qualified name
            last_part = last(children(node))
            if kind(last_part) == K"Identifier"
                identifier_text = string(last_part)
                return identifier_text in Infs
            end
        end
    end
    
    return false
end

function extract_inf_type(node::SyntaxNode)::String
    if kind(node) == K"Identifier"
        return string(node)
    elseif kind(node) == K"."
        # For qualified names like Base.Inf, return just the Inf part
        if length(children(node)) >= 2
            last_part = last(children(node))
            if kind(last_part) == K"Identifier"
                return string(last_part)
            end
        end
    end
    @debug "Unexpected shape of an assigned value (RHS)" node
    return ""
end


end # module DoNotSetVariablesToInf
