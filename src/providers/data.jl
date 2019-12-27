using Dates

include("../structures.jl")
include("sysstat.jl")
include("../util/util.jl")
include("../util/logger.jl")

function fetchData!(store::DataStore, attribute::DataAttribute)
    throw("Unknown data provider $(typeof(attribute))")
end

function fetchData!(
    store::DataStore,
    attribute::Sysstat,
    from::DateTime,
    to::DateTime,
)::Tuple{Array{DateTime,1},Array{Float64,1}, Tuple{String,String}}

    @assert "$(typeof(attribute))" == "Sysstat"

    local fqn = ("$(typeof(attribute))", attribute.property)
    if fqn in keys(store.data)
        return store.data[fqn]["$(attribute.context)"]..., fqn
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
        if length(h[2]) > 0
            store.descriptions[("$(typeof(attribute))", h[1])] = h[2]
        end
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
    
    return store.data[fqn]["$(attribute.context)"]..., fqn
end

function getPoints(store::DataStore, from::DateTime, to::DateTime)
    return filter( v->length(last(v)) > 0, Dict( key => filter(x -> from <= x <= to, value) for (key, value) in store.points))
end
