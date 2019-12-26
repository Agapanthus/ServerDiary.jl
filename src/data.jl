include(joinpath(@__DIR__, "queryStructure.jl"))
using Dates


mutable struct DataStore
    data::Dict{Tuple{String,String},Dict{String,Any}}
end
DataStore() = DataStore(Dict())

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
)::NTuple{2,Array{Any,1}}
    local fqn = (attribute.property, "$(typeof(attribute))")
    if fqn in keys(store.data)
        return store.data[fqn]["$(attribute.context)"]
    end

    local cmd, keyword = getCommand(attribute)
    local datas, points, header, description = collectData(cmd, keyword, from, to)

    for i in 2:length(header)
        fqn = (header[i][1], "$(typeof(attribute))")
        store.data[fqn] = Dict()
        for data in datas
            # TODO: Context is never used! Implement it! Reiterate until all elements of product exhausted!
            store.data[fqn]["$(DataAttributeContext(Set()))"] =
                (pseudoColumn(data[2], 1), pseudoColumn(data[2], i))
        end
    end

    fqn = (attribute.property, "$(typeof(attribute))")
    return store.data[fqn]["$(attribute.context)"]
end
