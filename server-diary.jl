include(joinpath(@__DIR__, "src", "stats.jl"))
include(joinpath(@__DIR__, "src", "email.jl"))
include(joinpath(@__DIR__, "src", "html.jl"))
include(joinpath(@__DIR__, "src", "args.jl"))


begin
    local today = Dates.now()
    local doc = StatsDocument()
    local args = getArguments()
    local path = ""

    for cmd in QUERY
        #logException(_->begin
            local results = getGraph(cmd[2], cmd[3], today)
            for (pngPath, header, description, specialization) in results
                path = pngPath
                doc = appendGraph(doc, basename(pngPath), header, description, cmd[1] * specialization)
            end
         #end, "gettings sar data for $cmd")
    end
    
    local html = generateHTML(doc)
    open( normpath(joinpath(path, "..", "stats.html")), "w") do io
        print(io, html)
    end
    local imgPath = dirname(path)
    open( joinpath(BASE_PATH, "stats.email"), "w") do io
        print(io, makeEmail(html, imgPath, args["email"], "Daily Report"))
    end
end