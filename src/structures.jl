abstract type QueryStruct end
abstract type QWidget end
abstract type DataAttribute <: QueryStruct end


############ Providers

struct DataAttributeContext
    ctx::Set{Tuple{String,String,String}}
end


struct Sysstat <: DataAttribute
    property::String
    #context::DataAttributeContext
end
#Sysstat(name::String) = Sysstat(name, DataAttributeContext(Set()))

struct Aws <: DataAttribute
    property::String
end

struct Postfix <: DataAttribute
    property::String
end

##############

using Dates

mutable struct DataStore
    data::Dict{Tuple{String,String},Dict{String,Tuple{DataAttributeContext,Array{DateTime,1},Array{Float64,1}}}}
    points::Dict{Tuple{String,String},Array{DateTime,1}}
    descriptions::Dict{Tuple{String,String},String}
end
DataStore() = DataStore(Dict(), Dict(), Dict())


############### widgets

mutable struct QPlot <: QWidget
    title::String
    days::Int64
    data::Array{<:QueryStruct,1}
    size::Union{Tuple{Int64,Int64},Nothing}
end
# line plot of the given structure
QPlot(
    title::String;
    days::Int64 = 3,
    data::Array{<:QueryStruct,1} = [],
    size::Union{Tuple{Int64,Int64},Nothing} = nothing,
) = QPlot(title, days, data, size)

mutable struct QStack <: QueryStruct
    stacked::Array{<:QueryStruct,1}
    ctxs::Union{Array{DataAttributeContext, 1},Nothing}
end
# stacks the select lines
QStack(data::Array{<:QueryStruct,1}; ctxs = nothing) = QStack(data, ctxs)
QStack(content::QueryStruct; ctxs = nothing) = QStack([content], ctxs)


# overrides the default styles for the given data
#   fillrange: nothing to prevent filling (for example when stacked) or a float to fill towards this number
#   color: line color
#   fillcolor: fill color
#   fillalpha: fill alpha
mutable struct QStyle <: QueryStruct
    data::QueryStruct
    overloads::Dict{String,Any}
end


mutable struct QGroup <: QueryStruct
    unit::String
    max::Union{Nothing,<:Number}
    min::Union{Nothing,<:Number}
    log::Bool
    data::Array{<:QueryStruct,1}
    ctxs::Union{Array{DataAttributeContext, 1},Nothing}
end
# assigns the unit to this group. Use this, to plot different units in the same plot
QGroup(
    unit::String;
    max::Union{Nothing,<:Number} = nothing,
    min::Union{Nothing,<:Number} = nothing,
    log::Bool = false,
    data::Array{<:QueryStruct,1} = [],
    ctxs = nothing
) = QGroup(unit, max, min, log, data, ctxs)

###########


mutable struct Palette
    palette
    index
end

mutable struct PlotContext
    plot
    palette::Palette
    styles::Dict{String,Any}
    today::DateTime
    store::DataStore
    maxDate::DateTime
    minDate::DateTime
    group::Int
end
PlotContext(;
    plot = nothing,
    palette = Palette(nothing, 1),
    styles::Dict{String,Any} = defaultStyles(),
    today::DateTime = Dates.now(),
    store::DataStore = DataStore(),
    maxDate::DateTime = Dates.now(),
    minDate::DateTime = Dates.now(),
    group::Int = 0,
) = PlotContext(plot, palette, styles, today, store, maxDate, minDate, group)
