using Dates

const BASE_PATH = normpath(joinpath(@__DIR__, "..", ".."))

# remove old log (it will grow fast)
isfile("$(BASE_PATH)sar_stats.log") && rm("$(BASE_PATH)sar_stats.log")

function logger(
    payload::Any,
    message::String = "",
    console::Bool = false;
    failed::Bool = false,
)
    open("$(BASE_PATH)sar_stats.log", "a") do io
        println(io, "$(Dates.now()) # $message")
        println(io, payload)
        println(io, "")
        if console
            println("$(Dates.now()) # $message # $payload")
        end
    end
end
