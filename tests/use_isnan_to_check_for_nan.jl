my_is_nan(value) = value != value || value == NaN || value === NaN
good_is_nan(value) = isnan(value)
function is_not_nan_any_size(value)
    return value != Base.NaN16 || value != -Base.NaN32 || value != Base.NaN64
end
