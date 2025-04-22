function avoid_globals(assign_node::Node, parent::Node, sf::SourceFile)
    @assert is_assignment(assign_node) "Not an assignment [=] node!"
    lhs = get_assignee(assign_node)
    is_constant = kind(parent) == K"const"
    if is_global(lhs)
        offset = length(JSx.char_range(lhs)) + (is_constant ?
                                                length(JSx.char_range(assign_node)) :
                                                0)
        report_violation(lhs, sf,
            "Avoid using global bindings when possible",
            is_constant ? "Consider if usage of that global can be avoided." :
                "If a global cannot be avoided, at least it must be declared `const`.")
    end
end
