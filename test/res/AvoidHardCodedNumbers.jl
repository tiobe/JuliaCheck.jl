module BadStyle

energy = m * 4.493_775_893_684_088e16
A = 3.14 * r ^ 2

const ONE_HALF::Float64 = 0.5
const TWO::Int64 = 2
A = pi * r ^ TWO
energy =  0.5 * m * v^TWO
energy =  ONE_HALF * m * v^2

universal_answer = 42

end # BadStyle

module GoodStyle

energy =  0.5 * mass * velocity^2

"C_SPEED_OF_LIGHT represents the speed of light in m/s"
const C_SPEED_OF_LIGHT::Float64 = 299792458.0
energy = mass * C_SPEED_OF_LIGHT^2

end # GoodStyle

module BadStyle2ndRound # That's when it will be reported

energy(m) = m * 4.493775893684088e16
Area(r) = 3.14 * r ^ 2

const ONE_HALF::Float64 = 0.5
A(r) = π * r ^ 2
energy(m, v) =  0.5 * m * v^2
energy_var =  ONE_HALF * m * v^2

universal_answer = 42

end # BadStyle2ndRound
