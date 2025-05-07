function BadFunName(x::T) where T<:Any  x end
function Get_Bacon()::Bacon end
function Get_bacon()::Bacon end
function GetBacon()::Bacon end
function Getbacon()::Bacon end
function get_Bacon()::Bacon end
function getBacon()::Bacon end
function get_SPAM_from_somewhere()::SPAM end

# Good
function get_bacon()::Bacon end
    