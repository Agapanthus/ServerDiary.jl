using Dates

include("../structures.jl")
include("sysstat.jl")
include("../util/util.jl")
include("../util/logger.jl")

function fetchData!(store::DataStore, attribute::DataAttribute)
    throw("Unknown data provider $(typeof(attribute))")
end


function fetchContext!(
    store::DataStore,
    attribute::Sysstat,
    from::DateTime,
    to::DateTime,
)::Dict{String, DataAttributeContext}

    local fqn = ("$(typeof(attribute))", attribute.property)
    if fqn in keys(store.data)
        return Dict(k=>v[1] for (k,v) in store.data[fqn])
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

    local srcCtx = Dict{String, DataAttributeContext}()
    local localCtx
    for i in 2:length(header)
        fqn = ("$(typeof(attribute))", header[i][1])
        store.data[fqn] = Dict()
        for data in datas
            local values = pseudoColumn(data[2], i)
            if length(header[i][3]) == 0
                values = convert(Array{Float64,1}, values)
            else
                logger("", "Scipping text column $(header[i][1])", true)
                continue
            end

            localCtx = DataAttributeContext(Set(map(
                x -> ("$(typeof(attribute))", "$(x[1])", "$(x[3])"),
                data[1],
            )))
            srcCtx["$localCtx"] = localCtx

            store.data[fqn]["$localCtx"] =
                (localCtx, pseudoColumn(data[2], 1), values)
        end
    end

    return srcCtx
end


function fetchData!(
    store::DataStore,
    attribute::Sysstat,
    ctx::DataAttributeContext,
    from::DateTime,
    to::DateTime,
)::Tuple{Array{DateTime,1},Array{Float64,1},Tuple{String,String}}

    @assert "$(typeof(attribute))" == "Sysstat"

    local fqn = ("$(typeof(attribute))", attribute.property)

    @assert fqn in keys(store.data)

    local myData = store.data[fqn]["$ctx"]
    
    myData = filter(x -> from <= x[1] <= to, collect(zip(myData[2], myData[3])))

    return pseudoColumn(myData, 1), pseudoColumn(myData, 2), fqn
end

function getPoints(store::DataStore, from::DateTime, to::DateTime)
    return filter(
        v -> length(last(v)) > 0,
        Dict(key => filter(x -> from <= x <= to, value) for (key, value) in store.points),
    )
end
