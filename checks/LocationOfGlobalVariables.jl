module LocationOfGlobalVariables

include("_common.jl")

using ...Properties: haschildren, is_export, is_global_decl, is_import, is_mod_toplevel,
                     is_triple_quote

struct Check<:Analysis.Check end
Analysis.id(::Check) = "location-of-global-variables"
Analysis.severity(::Check) = 7
function Analysis.synopsis(::Check)
    return "Global variables should be placed at the top of a module or file"
end

function Analysis.init(this::Check, ctxt::AnalysisContext)::Nothing
    register_syntaxnode_action(ctxt, is_global_decl, n -> _check(this, ctxt, n))
    return nothing
end

function _check(this::Check, ctxt::AnalysisContext, glob_decl::SyntaxNode)::Nothing
    @assert is_global_decl(glob_decl) "Expected a global declaration node, got $(kind(glob_decl))"
    toplevel = glob_decl.parent
    if !is_mod_toplevel(toplevel)
        # If the global declaration is not at the top level of a module, we
        # don't check it.
        return
    end
    for node in children(toplevel)
        if node === glob_decl
            return # we are done
        end
        if _is_allowed_before_const(node)
            continue
        end
        # Docstring constructions depend on whether the second child node is in the 'allowed list'.
        # First child is the docstring. Second child is the node we need to check.
        if kind(node) == K"doc"
            commented_node = children(node)[2]
            if _is_allowed_before_const(commented_node)
                continue
            end
        end
        report_violation(ctxt, this, glob_decl, synopsis(this))
    end
    return nothing
end

# Imports, exports, (other) global declarations and triple-quote comments are allowed
# to be present before global declarations. Regular #-prefixed comments do not show
# up in the syntax tree; they are only present in the green tree.
function _is_allowed_before_const(node::SyntaxNode)::Bool
    return is_import(node) || is_export(node) || is_global_decl(node) || is_triple_quote(node)
end

end # LocationOfGlobalVariables
