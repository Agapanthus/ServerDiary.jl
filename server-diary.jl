include(joinpath(@__DIR__, "src", "widget.jl"))
include(joinpath(@__DIR__, "src", "email.jl"))
include(joinpath(@__DIR__, "src", "html.jl"))
include(joinpath(@__DIR__, "src", "args.jl"))


begin
    local today = Dates.now()
    local doc = StatsDocument()
    local args = getArguments()
    local path = ""

    for widget in QUERY
        # TODO: Debug
        #logException(_->begin
            local results = renderWidget(widget, today)
            for (pngPath, header, description, specialization) in results
                path = pngPath
                doc = appendGraph(doc, basename(pngPath), header, description, widget.title * specialization)
            end
        #end, "gettings sar data for $(widget.title)")
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