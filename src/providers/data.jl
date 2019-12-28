using Dates

include("../structures.jl")
include("../util/util.jl")
include("../util/logger.jl")

function fetchData!(store::DataStore, attribute::DataAttribute)
    throw("Unknown data provider $(typeof(attribute))")
end


include("sysstat.jl")
include("aws.jl")
