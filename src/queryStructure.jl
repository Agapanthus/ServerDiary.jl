
abstract type QueryStruct end
abstract type QWidget end
abstract type DataAttribute <: QueryStruct end


mutable struct QPlot <: QWidget
    title::String
    days::Int64
    data::Array{<:QueryStruct,1}
    size::Union{Tuple{Int64,Int64}, Nothing}
end
# line plot of the given structure
QPlot(
    title::String;
    days::Int64 = 3,
    data::Array{<:QueryStruct,1} = [],
    size::Union{Tuple{Int64,Int64}, Nothing} = nothing,
) = QPlot(title, days, data, size)

mutable struct QStack <: QueryStruct
    stacked::Array{<:QueryStruct,1}
end
# stacks the select lines
#QStack(data::Array{<:QueryStruct,1}) = QStack(data)
QStack(content::QueryStruct) = QStack([content])


# overrides the default styles for the given data
#   fillrange: nothing to prevent filling (for example when stacked) or a float to fill towards this number
#   color: line color
#   fillcolor: fill color
#   fillalpha: fill alpha
mutable struct QStyled <: QueryStruct
    data::QueryStruct
    overloads::Dict{String,Any}
end


mutable struct QGroup <: QueryStruct
    unit::String
    max::Union{Nothing,<:Number}
    min::Union{Nothing,<:Number}
    log::Bool
    data::Array{<:QueryStruct,1}
end
# assigns the unit to this group. Use this, to plot different units in the same plot
QGroup(
    unit::String;
    max::Union{Nothing,<:Number} = nothing,
    min::Union{Nothing,<:Number} = nothing,
    log::Bool = false,
    data::Array{<:QueryStruct,1} = [],
) = QGroup(unit, max, min, log, data)


############ Providers

struct DataAttributeContext
    ctx::Set{Tuple{String,String}}
end


struct Sysstat <: DataAttribute
    property::String
    context::DataAttributeContext
end
Sysstat(name::String) = Sysstat(name, DataAttributeContext(Set()))

struct Aws <: DataAttribute
    property::String
end

struct Postfix <: DataAttribute
    property::String
end

