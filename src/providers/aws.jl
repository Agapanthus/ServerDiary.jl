include("../structures.jl")

# aws ce get-cost-and-usage --time-period Start=2019-12-01,End=2019-12-28     --granularity DAILY    --metrics "BlendedCost" "UnblendedCost" "UsageQuantity"     --group-by Type=DIMENSION,Key=SERVICE Type=TAG,Key=Environment --region us-east-1
import JSON
function getTheData(
    from::DateTime,
    to::DateTime
    )

    local s = open("hidden.json") do file
        read(file, String)
    end
    return JSON.parse(s)

    # TODO: implement something here!
    # TODO: Prevent executing this multiple times! 

end


function fetchData!(
    store::DataStore,
    attribute::Aws,
    ctx::DataAttributeContext,
    from::DateTime,
    to::DateTime,
)::Tuple{Array{DateTime,1},Array{Float64,1},Tuple{String,String}}

    local dataLines = Dict{String, Array{Tuple{DateTime,Float64}, 1}}()
    for event in getTheData(from, to)["ResultsByTime"]
        local start = Dates.Date(event["TimePeriod"]["Start"])
        for group in event["Groups"]
            for (metric, value) in group["Metrics"]
                local key = metric * " " * group["Keys"][1]
                if !(key in keys(dataLines))
                    dataLines[key] = []
                end
                push!(dataLines[key], (start, parse(Float64, value["Amount"])))
            end
        end
    end

    # fill it
    for event in getTheData(from, to)["ResultsByTime"]
        local start = Dates.Date(event["TimePeriod"]["Start"])
        for (k,v) in dataLines
            local found = false
            for (d,x) in v
                if d == start
                    found = true
                    break
                end
            end
            if found
                continue
            end
            
            push!(dataLines[k], (start, .0))
        end      
    end
    for (k,v) in dataLines
        dataLines[k] = sort(v, by=x->x[1])
    end

    return pseudoColumn(dataLines[attribute.property],1), pseudoColumn(dataLines[attribute.property],2), ("Aws", attribute.property)

    # TODO: We need a feature to select all data lines matching something, e.g. all Groups
end


function fetchContext!(
    store::DataStore,
    attribute::Aws,
    from::DateTime,
    to::DateTime,
)::Dict{String, DataAttributeContext}
    local ctx = DataAttributeContext(Set())
    return Dict("$ctx" => ctx)
end

# @show fetchData!(DataStore(), Aws("BlendedCost Amazon DynamoDB"), DataAttributeContext(Set()), Dates.now(), Dates.now())