const BASE_PATH = normpath(joinpath(@__DIR__, ".."))

# remove old log (it will grow fast)
isfile("$(BASE_PATH)sar_stats.log") && rm("$(BASE_PATH)sar_stats.log")

function logger(payload::Any, message::String = "", console::Bool=false; failed::Bool=false)
    open("$(BASE_PATH)sar_stats.log", "a") do io
        println(io, "$(Dates.now()) # $message")
        println(io, payload)
        println(io, "")
        if console
            println("$(Dates.now()) # $message # $payload")
        end
    end
end
logger("", "Starting SAR Plotter", true)



# executes cmd and returns (stdout, stderr)
function exe(cmd::Any)::Tuple{String,String}
    logger(cmd, "executing")

    local time = @timed begin
        local err = Pipe()
        local out = Pipe()
        local proc = run(pipeline(ignorestatus(cmd),stdout=out,stderr=err))
        close(err.in)
        close(out.in)
        local stdout = String(read(out))
        local stderr = String(read(err))
        length(stdout) == 0 || logger(stdout, "stdout")
        length(stderr) == 0 || logger(stderr, "stderr")
    end
    logger("$(time[2])s", "time")
    return (stdout, stderr)
end


const NUM_REGEXP = r"^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$";
const isNumericString(str) = occursin(NUM_REGEXP,str)


function logException(f, operation)
    try
        f(nothing)
    catch exception
        bt = catch_backtrace()
        msg = sprint(showerror, exception, bt)
        logger(msg, "$operation failed", true, failed=true)
    end
end


function pseudoColumn(data::Array{Array{Any,1},1}, n::Int)::Array{Any,1}
    local column = []
    for d in data
        push!(column, d[n])
    end
    return column
end

function sanitizeFile(name::String)::String
    return replace(name, r"(\/|\\)"=>"?")
end