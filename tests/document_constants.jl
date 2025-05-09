
# Bad
const MAG_THRESHOLD1::Float64 = 3.00 # In ppm
const MAG_THRESHOLD2::Float64 = 1.00 # Dimensionless
const MAG_THRESHOLD3::Float64 = 0.00 # Dimensionless

# Good
"MAG_THRESHOLD is dimensionless. A value of 1 means no expansion."
const MAG_THRESHOLD4::Float64 = 1.0 + 3e-6

"MAG_THRESHOLD is dimensionless. A value of 0 means no expansion."
const MAG_THRESHOLD5::Float64 = 3e-6
