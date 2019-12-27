import Dates
using Dates

include("../util/util.jl")

include("../../conf.jl")

include("base.jl")

include("qGroups.jl")
include("qStacks.jl")
include("qStyles.jl")
include("qAttributes.jl")

include("../providers/data.jl")

###############################

println("Loading Plots...")

@time begin
    using Plots
    using PlotThemes
    using Plots.PlotMeasures
    # Don't try to open windows for the plots
    ENV["GKSwstype"] = "nul"
    gr()
    # init it now
    theme(PLOT_THEME)
    plot([0], [0])
    logger(clibraries(), "clibraries()")
end

############################


function addTicks!(datesI::Array{DateTime,1}, ctx::PlotContext)
    # Add x-tick-labels
    local datesTicks = Array{DateTime,1}()
    local datesLabels = Array{String,1}()
    local dates = sort(datesI) # copy and sort
    local lastDay = 0
    local tickDistance = (dates[end] - dates[1]) ÷ NUMBER_OF_TICKS
    local lastTick = 0

    # add interval and day based ticks
    for date in dates
        local day = Dates.format(date, "dd")
        if day != lastDay
            push!(datesLabels, Dates.format(date, "yy/mm/dd")) # HH:MM"))
            push!(datesTicks, date)
            lastDay = day
            lastTick = date
        elseif NUMBER_OF_TICKS > 0 && date - lastTick >= tickDistance
            push!(datesLabels, Dates.format(date, "HH:MM"))
            push!(datesTicks, date)
            lastTick = date
        end
    end
    # add hour based ticks
    if NUMBER_OF_TICKS < 0
        local cpDatesTicks = copy(datesTicks)
        for i in 1:length(cpDatesTicks)
            local date = cpDatesTicks[i]
            local now = date + Dates.Hour(-NUMBER_OF_TICKS)
            while now < date + Dates.Hour(24) && now < dates[end] && now < ctx.maxDate && (
                i == length(cpDatesTicks) ||
                now < cpDatesTicks[i+1] + Dates.Hour(round(-NUMBER_OF_TICKS / 2))
            )
                push!(datesLabels, Dates.format(now, "HH:MM"))
                push!(datesTicks, now)
                now += Dates.Hour(-NUMBER_OF_TICKS)
            end
        end
    end
    plot!(ctx.plot, xticks = (datesTicks, datesLabels))
end

function addBackground!(dates::Array{DateTime,1}, ctx::PlotContext)
    local lastDay = 0
    for date in dates
        local day = Dates.format(date, "dd")
        if day != lastDay
            local range = [
                Dates.DateTime(Dates.format(date, "yyyy/mm/dd 00:00"), "yyyy/mm/dd HH:MM"),
                min(
                    Dates.DateTime(
                        Dates.format(date, "yyyy/mm/dd 06:00"),
                        "yyyy/mm/dd HH:MM",
                    ),
                    ctx.maxDate,
                ),
            ]
            vspan!(ctx.plot, range, color = :blue, alpha = 0.05, labels = "")
            lastDay = day
        end
    end
end

function addPoints!(points::Dict{Tuple{String,String},Array{DateTime,1}}, ctx::PlotContext)
    # plot points
   
    for (label, ps) in points
        vline!(
            ctx.plot,
            ps,
            label = label[2],
            color = nextColor!(ctx.palette)
        )

        # TODO: Scatter is more beautiful. But where on the yaxis do we place the points?
        # _on_ the xaxis would look nice. But that is not possible (?)

        #=scatter!(
            ctx.plot,
            ps,
            [.0 for _ in 1:length(ps)],
            label = label[2],
            color = nextColor!(ctx.palette),
        )=#
    end
end

global globalDataStore = DataStore()

function analyze(widget::QPlot, ctx::PlotContext)
    local dates = Set{DateTime}()
    local srcCtx = Array{String,1}()
    local mini = typemax(Float64)
    local maxi = typemin(Float64)
    local titles = Array{String,1}()

    for attr in widget.data
        local _dates, _values, _srcCtx, _mini, _maxi, _titles = analyze(attr, ctx)

        @assert length(_dates) == length(_values)
        for c in _dates
            push!(dates, c)
        end
        for c in _srcCtx
            push!(srcCtx, c)
        end
        mini = min(mini, minimum(_values), _mini)
        maxi = max(maxi, maximum(_values), _maxi)
        titles = [titles..., _titles...]
    end

    return sort(collect(dates)), nothing, srcCtx, mini, maxi, titles
end

function renderWidget(widget::QPlot, today::DateTime, saveTo::String)
    logger("", "Plotting $(widget.title)", true)

    local from = today - Dates.Day(widget.days)
    local to = today

    local size = widget.size
    if size === nothing
        size = DEFAULT_SIZE
    end
    local palette = loadPalette(PLOT_THEME)

    # init the plot
    local p = plot(
        left_margin = 5mm,
        title = widget.title,
        size = size,
        legend = :topleft,
        yformatter = Y_FORMATTER,
    )
    local ctx = PlotContext(
        plot = p,
        palette = palette,
        today = today,
        store = globalDataStore,
        maxDate = to,
        minDate = from,
    )
    local dates, values, srcCtx, mini, maxi, titles = analyze(widget, ctx)

    if DRAW_NIGHT_BACKGROUND
        addBackground!(dates, ctx)
        # vspan overwrites the default format. Restore it.
        plot!(ctx.plot, yformatter = Y_FORMATTER)
    end

    for el in widget.data
        ctx.styles = defaultStyles()
        renderWidget!(el, ctx)
    end

    local points = getPoints(globalDataStore, from, to)
    
    addPoints!(points, ctx)
    addTicks!(dates, ctx)
    plot!(ctx.plot, yformatter = Y_FORMATTER)

    # save to plot
    mkpath(saveTo)
    local path = joinpath(saveTo, "$(sanitizeFile(widget.title)).png")
    savefig(ctx.plot, path)

    # TODO: Add specialization
    local title = widget.title

    # TODO: Generate Description from Specialization data!
    local description = ""

    titles = map(titles) do x
        local str = ""
        if x in keys(globalDataStore.descriptions)
            str = globalDataStore.descriptions[x]
        end
        (x..., str)
    end


    @assert isfile("$path") "Error saving the Plot"

    # Apply strong png compression to make e-mail smaller
    if USE_PNGQUANT
        exe(`pngquant --quality=60-80 --force --output $path $path`)
    end
    
    return [
        (path, titles, title, description),
    ]
end


# renderWidget(QUERY[1], Dates.now(), joinpath(BASE_PATH, "stats"))

