module BadStyle

energy = m * 4.493_775_893_684_088e16
A = 3.14 * r ^ 2

const ONE_HALF::Float64 = 0.5
const TWO::Int64 = 2
A = pi * r ^ TWO
energy =  0.5 * m * v^TWO
energy =  ONE_HALF * m * v^2

universal_answer = 42

# Including 10^19 and 10^20 in allowed values (out of int64 range)
# caused false negatives due to wraparound
wraparound_overflow_19 = -8446744073709551616
wraparound_overflow_20 = 7766279631452241920
wraparound_overflow_19_neg = 8446744073709551616
wraparound_overflow_20_neg = -7766279631452241920

nok_floats = max(1.1, 1.1, 0.2, 1.1, 1000.1, 1.1, 0.2, 0.2, 1000.1)
end # BadStyle

module GoodStyle

energy =  0.5 * mass * velocity^2

"C_SPEED_OF_LIGHT represents the speed of light in m/s"
const C_SPEED_OF_LIGHT::Float64 = 299792458.0
energy = mass * C_SPEED_OF_LIGHT^2

# ok: known values
ok_floats = max(0.1, 1.0, 0.0, 1.0, 1000.0, 1.0, 0.0, 0.1, 1000.0)

# ok: multi-dim array in function call
converted = convert.(Float64, [[2, 8446744073709551616, 42, 5.76, 3.14], [2, 8446744073709551616, 42, 5.76, 3.14]])

# ok: array literal
weights_vec = [2.2, 1.2, 3.4, 4.5, 2.2, 2.2, 1.2, 3.4, 4.5]
end # GoodStyle

module BadStyle2ndRound # That's when it will be reported

energy(m) = m * 4.493775893684088e16
Area(r) = 3.14 * r ^ 2

const ONE_HALF::Float64 = 0.5
A(r) = π * r ^ 2
energy(m, v) =  0.5 * m * v^2
energy_var =  ONE_HALF * m * v^2

universal_answer = 42

# Including 10^19 and 10^20 in allowed values (out of int64 range)
# caused false negatives due to wraparound
another_vectorwraparound_overflow_19 = -8446744073709551616
another_vectorwraparound_overflow_20 = 7766279631452241920
another_vectorwraparound_overflow_19_neg = -7766279631452241920
another_vectorwraparound_overflow_20_neg = 8446744073709551616

end # BadStyle2ndRound
