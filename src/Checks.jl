module Checks

using ..Properties: to_pascal_case

export check, load_rules, setup_filter

# Types
struct CheckInfo
    id::String
    user_msg::String
    summary::String
    severity::UInt8
    check_function::Function
    enabled::Bool
end


# Global registry of all available checks
const CHECK_REGISTRY = Dict{String, CheckInfo}()


"""
    register_check!(check_function::Function;
                    id::String, severity::Symbol,
                    user_msg::String, summary::String)

Register a check function with its metadata.

# Arguments
- `check_function`: Function that performs the check.
- `id`: Unique identifier for the check (e.g., "nan-assignment").
- `user_msg`: Message given to users in case of violation.
- `summary`: Brief description of what the check does.
- `severity`: Severity level (reverse numerical: the lower the number, the
        higher the severity)
"""
function register_check!(check_function::Function,
                        id::String, severity::Int,
                        user_msg::String, summary::String)
    global CHECK_REGISTRY
    if haskey(CHECK_REGISTRY, id)
        @warn "Check with id '$id' already exists. Overwriting."
    end
    CHECK_REGISTRY[id] = CheckInfo(id, user_msg, summary, severity,
                                   check_function, true)
    @debug "Registered check: $id"
    return nothing
end

function load_check(fname::String)
    try
        include("../$fname")
        mod_name = to_pascal_case(basename(fname)[1:end-3])    # take only the file name without extension
        mod = getfield(Checks, Symbol(mod_name))
        func =     getfield(mod, Symbol("check"))
        id =       getfield(mod, Symbol("RULE_ID"))
        user_msg = getfield(mod, Symbol("USER_MSG"))
        summary  = getfield(mod, Symbol("SUMMARY"))
        severity = getfield(mod, Symbol("SEVERITY"))
        register_check!(func, id, severity, user_msg, summary)
    catch x
        @warn "Failed to load '$fname':" x
    end
end

# Beware! Cannot use `__init__` to load checks automatically, in a loop.

do_nothing(node...) = nothing

function setup_filter(enabled::Vector{String})
    global CHECK_REGISTRY
    if isempty(enabled)
        # All rules are enabled. Exit.
        return nothing
    end
    for (id, check) in CHECK_REGISTRY
        if id ∉ enabled
            old_info = CHECK_REGISTRY[id]
            CHECK_REGISTRY[id] = CheckInfo(old_info.id, old_info.user_msg,
                                           old_info.summary, old_info.severity,
                                           do_nothing, false)
            @debug "Disabled check: $id"
        end
    end
end

function check(rule_id::String, node...)
    global CHECK_REGISTRY
    @assert rule_id ∈ keys(CHECK_REGISTRY) "rule_id '$rule_id' missing from CHECK_REGISTRY"
    return CHECK_REGISTRY[rule_id].check_function(node...)
end

load_check("checks/document_constants.jl")
load_check("checks/do_not_set_variables_to_nan.jl")
load_check("checks/do_not_set_variables_to_inf.jl")
load_check("checks/function_identifiers_in_lower_snake_case.jl")
load_check("checks/function_arguments_in_lower_snake_case.jl")
load_check("checks/indentation_levels_are_four_spaces.jl")
load_check("checks/implement_unions_as_consts.jl")
load_check("checks/infinite_while_loop.jl")
load_check("checks/leading_and_trailing_digits.jl")
load_check("checks/long_form_functions_have_a_terminating_return_statement.jl")
load_check("checks/module_end_comment.jl")
load_check("checks/module_import_location.jl")
load_check("checks/module_include_location.jl")
load_check("checks/module_name_casing.jl")
load_check("checks/module_single_import_line.jl")
load_check("checks/no_whitespace_around_type_operators.jl")
load_check("checks/prefix_of_abstract_type_names.jl")
load_check("checks/short_hand_function_too_complicated.jl")
load_check("checks/single_module_file.jl")
load_check("checks/struct_members_are_in_lower_snake_case.jl")
load_check("checks/too_many_types_in_unions.jl")
load_check("checks/type_names_upper_camel_case.jl")
load_check("checks/use_spaces_instead_of_tabs.jl")
load_check("checks/use_isinf_to_check_for_infinite.jl")
load_check("checks/use_ismissing_to_check_for_missing_values.jl")
load_check("checks/use_isnan_to_check_for_nan.jl")
load_check("checks/use_isnothing_to_check_for_nothing_values.jl")
#  include("checks/avoid_global_variables.jl")
#  include("checks/space_around_infix_operators.jl")

end
