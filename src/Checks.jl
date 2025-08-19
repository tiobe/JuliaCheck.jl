module Checks

using ..Properties: to_pascal_case

export is_enabled, filter_rules

CHECK_REGISTRY = Set{String}()
LOADED_CHECKS = Set{String}()


function is_enabled(id::String)
    global CHECK_REGISTRY
    return id ∈ CHECK_REGISTRY
end

# Load all check modules and populate LOADED_CHECKS at module load time
function __init_checks__()
    global LOADED_CHECKS
    for f in readdir(joinpath(@__DIR__, "../checks/"), join=true)
        if endswith(f, ".jl")
            try
                include("$f")
                fname = to_pascal_case(basename(f)[1:end-3])
                mod = getfield(Checks, Symbol(fname))
                id = getfield(mod, Symbol("RULE_ID"))
                push!(LOADED_CHECKS, id)
            catch exception
                @warn "Failed to load '$f':" exception
            end
        end
    end
end

__init_checks__()

function filter_rules(enabled::Set{String})
    global CHECK_REGISTRY
    if isempty(enabled)
        @debug "All rules enabled"
        CHECK_REGISTRY = LOADED_CHECKS
    else
        CHECK_REGISTRY = intersect(LOADED_CHECKS, enabled)
        @debug "Enabled rules:\n" * join(CHECK_REGISTRY, "\n")

        invalid = setdiff(enabled, LOADED_CHECKS)
        if !isempty(invalid)
            @warn "Unrecognized rules:" invalid
        end
    end
    return nothing
end

end
