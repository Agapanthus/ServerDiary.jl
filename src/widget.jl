include(joinpath(@__DIR__, "..", "conf.jl"))
include(joinpath(@__DIR__, "plot.jl"))
include(joinpath(@__DIR__, "queryStructure.jl"))
include(joinpath(@__DIR__, "stats.jl"))
include(joinpath(@__DIR__, "util.jl"))
# TODO: Use modules instead!



function renderWidget(widget::QWidget, today::DateTime, saveTo::String) #::Array{Tuple{String, Any, String, String},1}

    logger(widget, "Unknwon widget type $(typeof(widget))", true)

    throw("Unknwon widget type $(typeof(widget))")

    #=
    local datas, points, header, description
    local results = []
    if length(keyword) == 0
        datas, points, header, description = collectData(command, "", SHOW_DAYS, today)
    else
        datas, points, header, description = collectData(command, keyword, SHOW_DAYS, today)
    end
    for data in datas
        local title =
            "-$(command) $(keyword) " * reduce(*, map(d -> "$(d[1])=$(d[3]) ", data[1]))
        local specialization = reduce(*, map(d -> " $(d[1])=$(d[3])", data[1]))
        local exDescription =
            description *
            "\n" *
            reduce(*, map(d -> "$(d[3]) ($(d[1])) - $(d[2])\n", data[1]))

        local pngPath =
            joinpath(BASE_PATH, "stats", Dates.format(Dates.now(), "yyyy-mm-dd"))
        mkpath(pngPath)
        local pngPlace = joinpath(pngPath, title[2:end])

        # Generate the image
        makeDiagram(data[2], points, header, exDescription, title, pngPlace)

        pngPlace *= ".png"
        @assert isfile("$pngPlace") "Error saving the Plot"

        # Apply strong png compression to make e-mail smaller
        exe(`pngquant --quality=60-80 --force --output $pngPlace $pngPlace`)

        # cleanup
        # rm("$pngPlace")
        push!(results, ("$pngPlace", header, exDescription, specialization))

    end

    return results
    =#
end

renderWidget(QUERY[1], Dates.now(), joinpath(BASE_PATH, "stats"))
