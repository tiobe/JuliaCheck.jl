struct Point{T}
    x::T
    y::T
end
struct Point{T} <: Pointy{T}
    x::T
    y::T
end
mutable struct MeasurementContextBad
    Dir
    NominalPosition::Point
    IntrafieldPosition::Point

    MeasurementContextBad()=new("foo", nothing, nothing)
end
struct MeasurementContextGood <: AbstractMeasurementContext
    direction::Direction
    nominal_position::Point
    intrafield_position::Point
end
