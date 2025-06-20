module Checks

using ..Properties: to_pascal_case

export is_enabled, setup_filter


function setup_filter(enabled::Set{String})
    global CHECK_REGISTRY
    if isempty(enabled)
        @debug "All rules enabled"
    else
        intersect!(CHECK_REGISTRY, enabled)
        @debug "Enabled rules:" CHECK_REGISTRY
        invalid = setdiff(enabled, CHECK_REGISTRY)
        if !isempty(invalid)
            @warn "Unrecognized rules:" invalid
        end
    end
end

function is_enabled(id::String)
    global CHECK_REGISTRY
    return id ∈ CHECK_REGISTRY
end

##===================== Executable code =====================##
ids_list = String[]
sizehint!(ids_list, 64)
for f in readdir("checks/"; join=true)
    if isfile(f) && endswith(f, ".jl")
        try
            include("../$f")
            f = to_pascal_case(basename(f)[1:end-3])    # take only the file name without extension (.jl)
            mod = getfield(Checks, Symbol(f))
            id =  getfield(mod, Symbol("RULE_ID"))
            push!(ids_list, id)
        catch x
            @warn "Failed to load '$f':" x
        end
    end
end
@debug "Loaded checks:" ids_list

global const CHECK_REGISTRY = Set{String}(ids_list)

end
