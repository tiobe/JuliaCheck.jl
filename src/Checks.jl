module Checks

using JuliaSyntax: SyntaxNode
using ..Properties: to_pascal_case

export setup_filter, check

RULES::Vector{String} = []

function setup_filter(rules::Vector{String})
    RULES = map(to_pascal_case, rules)
end

# TODO: Do rule filtering here? Get the list/set of enabled/disabled rules and...
# Then what?
# 1. Get the disabled rules and overload their `check` function to return nothing
#   * Need to map rule id to the right module/function
#
# 2. Don't change the functions but let them know which one is disabled, by
#    passing the list/set and let each of them figure out.
#
# 3. Change the `check` functions to take a Bool flag. Here, export new overloads
#    of those functions created by partial application, fixing those flags to
#    either true or false to enable or disable them.

# include("../checks/check_avoid_globals.jl")
include("../checks/check_document_constants.jl")
include("../checks/check_do_not_set_variables_to_inf.jl")
include("../checks/check_do_not_set_variables_to_nan.jl")
include("../checks/check_function_arguments_in_lower_snake_case.jl")
include("../checks/check_function_identifiers_in_lower_snake_case.jl")
include("../checks/check_indentation_levels_are_four_spaces.jl")
include("../checks/check_implement_unions_as_consts.jl")
include("../checks/check_infinite_while_loop.jl")
include("../checks/check_leading_and_trailing_digits.jl")
include("../checks/check_long_form_functions_have_a_terminating_return_statement.jl")
include("../checks/check_module_end_comment.jl")
include("../checks/check_module_import_location.jl")
include("../checks/check_module_include_location.jl")
include("../checks/check_module_name_casing.jl")
include("../checks/check_module_single_import_line.jl")
include("../checks/check_no_whitespace_around_type_operators.jl")
include("../checks/check_prefix_of_abstract_type_names.jl")
include("../checks/check_short_hand_function_too_complicated.jl")
include("../checks/check_single_module_file.jl")
# include("../checks/check_space_around_infix_operators.jl")
include("../checks/check_struct_members_are_in_lower_snake_case.jl")
include("../checks/check_too_many_types_in_unions.jl")
include("../checks/check_type_names_upper_camel_case.jl")
include("../checks/check_use_spaces_instead_of_tabs.jl")
include("../checks/check_use_isinf_to_check_for_infinite.jl")

function check(rule_id::String, node::SyntaxNode)
    if isempty(RULES) || rule_id ∈ RULES
        func = eval(Meta.parse("$rule_id.check"))
        return func(node)
    end
end

function check(rule_id::String, node::SyntaxNode, second::SyntaxNode)
    if isempty(RULES) || rule_id ∈ RULES
        func = eval(Meta.parse("$rule_id.check"))
        return func(node, second)
    end
end

end
