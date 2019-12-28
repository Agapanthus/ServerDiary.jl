__precompile__()
module ServerDiary
export writeDiary


include("util/util.jl")
include("util/Args.jl")
using .Args: getArguments

include("widgets/qWidgets.jl")
include("output/email.jl")
include("output/html.jl")

import Dates

include(joinpath(@__DIR__, "..", "conf.jl"))

function writeDiary()
    logger("", "Writing Diary...", true)

    local today = Dates.now()
    local doc = StatsDocument()
    local args = getArguments()
    local path = ""

    for widget in QUERY
        logException(_->begin
            local results = renderWidget(widget, today, joinpath(BASE_PATH, "stats", Dates.format(Dates.now(), "yyyy-mm-dd")) )
            for (pngPath, titles, title, description) in results
                path = pngPath
                doc = appendGraph(doc, basename(pngPath), titles, string(description), title)
            end
        end, "gettings sar data for $(widget.title)")
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

end