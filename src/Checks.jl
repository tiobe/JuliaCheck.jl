module Checks

include("../checks/check_avoid_globals.jl")
export avoid_globals

include("../checks/check_space_around_infix_operators.jl")
export space_around_infix_operators

end
