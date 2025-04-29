module AvoidGlobals

using JuliaSyntax: @K_str, @KSet_str, kind, SyntaxNode

include("../src/SymbolTable.jl")
using .SymbolTable: is_global

using ...Properties: is_assignment, get_assignee, report_violation

export check

function check(assign_node::SyntaxNode)
    # @assert is_assignment(assign_node) "Not an assignment [=] node!"
    lhs = get_assignee(assign_node)
    is_constant = kind(assign_node.parent) == K"const"
    if is_global(lhs)
        report_violation(lhs,
            "Avoid using global variables when possible",
            is_constant ? "Consider if usage of that global can be avoided." :
                "If a global cannot be avoided, at least it must be declared `const`.")
    end
end

end
