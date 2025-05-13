struct Point{T}
    x::T
    y::T
end
struct Point{T} <: Pointy{T}
    x::T
    y::T
end
struct MeasurementContextBad
    Dir::Direction
    NominalPosition::Point
    IntrafieldPosition::Point
end
struct MeasurementContextGood <: AbstractMeasurementContext
    direction::Direction
    nominal_position::Point
    intrafield_position::Point
end
