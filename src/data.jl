include(joinpath(@__DIR__, "queryStructure.jl"))
using Dates
include(joinpath(@__DIR__, "sarDB.jl"))
include(joinpath(@__DIR__, "stats.jl"))



mutable struct DataStore
    data::Dict{Tuple{String,String},Dict{String,Tuple{Array{DateTime,1},Array{Float64,1}}}}
    points::Dict{Tuple{String,String},Array{DateTime,1}}
    descriptions::Dict{Tuple{String,String},String}
end
DataStore() = DataStore(Dict(), Dict(), Dict())

function fetchData!(store::DataStore, attribute::DataAttribute)
    throw("Unknown data provider $(typeof(attribute))")
end


function getCommand(attr::Sysstat)
    for (letter, (command, description, content)) in SAR_DB
        for (k, v) in content
            if typeof(v) <: String
                if k == attr.property
                    return letter, ""
                end
            else
                for (l, u) in v[2]
                    if l == attr.property
                        return letter, k
                    end
                end
            end
        end
    end
    return nothing, nothing
end

function fetchData!(
    store::DataStore,
    attribute::Sysstat,
    from::DateTime,
    to::DateTime,
)::Tuple{Array{DateTime,1},Array{Float64,1}}

    @assert "$(typeof(attribute))" == "Sysstat"

    local fqn = ("$(typeof(attribute))", attribute.property)
    if fqn in keys(store.data)
        return store.data[fqn]["$(attribute.context)"]
    end

    local cmd, keyword = getCommand(attribute)
    local datas, points, header, description = collectData(cmd, keyword, from, to)

    for p in points
        local i = ("$(typeof(attribute))", p[2])
        if i ∉ keys(store.points)
            store.points[i] = []
        end
        push!(store.points[i], p[1])
    end

    for h in header[2:end]
        store.descriptions[("$(typeof(attribute))", h[1])] = h[2]
    end

    for i in 2:length(header)
        fqn = ("$(typeof(attribute))", header[i][1])
        store.data[fqn] = Dict()
        for data in datas
            # TODO: Context is never used! Implement it! Reiterate until all elements of product exhausted!
            local values = pseudoColumn(data[2], i)
            if length(header[i][3]) == 0
                values = convert(Array{Float64,1}, values)
            else
                logger("", "Scipping text column $(header[i][1])", true)
                continue
            end
            store.data[fqn]["$(DataAttributeContext(Set()))"] =
                (pseudoColumn(data[2], 1), values)
        end
    end

    fqn = ("$(typeof(attribute))", attribute.property)

    return store.data[fqn]["$(attribute.context)"]
end

function getPoints(store::DataStore, from::DateTime, to::DateTime)
    @show store.points
    return filter( v->length(last(v)) > 0, Dict( key => filter(x -> from <= x <= to, value) for (key, value) in store.points))
end
