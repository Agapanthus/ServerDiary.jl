include(joinpath(@__DIR__, "src", "stats.jl"))
include(joinpath(@__DIR__, "src", "email.jl"))
include(joinpath(@__DIR__, "src", "args.jl"))


begin
    local today = Dates.now()
    local email = Email()
    local args = getArguments()

    for cmd in QUERY
        logException(_->begin
            email = appendGraphToEmail(email, getGraphSysstat(cmd[1], cmd[2], today)...)
         end, "gettings sar data for $cmd")
    end
    
    open("$(BASE_PATH)stats.email", "w") do io
        print(io, finish(email, args["email"], "Daily Report"))
    end
end