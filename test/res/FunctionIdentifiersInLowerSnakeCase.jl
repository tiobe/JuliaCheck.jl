function BadFunName(x::T) where T<:Any return x end
function Get_Bacon()::Bacon return nothing end
function Get_bacon()::Bacon return nothing end
function GetBacon()::Bacon return nothing end
function Getbacon()::Bacon return nothing end
function get_Bacon()::Bacon return nothing end
function getBacon()::Bacon return nothing end
function get_SPAM_from_somewhere()::SPAM return nothing end

# Good
function get_bacon()::Bacon return nothing end
