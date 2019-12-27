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
        vline!(ctx.plot, ps, label = label[2], color = nextColor!(ctx.palette))

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
    local srcCtx = Dict{String,DataAttributeContext}()
    local mini = typemax(Float64)
    local maxi = typemin(Float64)
    local titles = Array{String,1}()

    for attr in widget.data
        local _dates, _values, _srcCtx, _mini, _maxi, _titles = analyze(attr, ctx)

        @assert length(_dates) == length(_values) "$(length(_dates)) == $(length(_values))"
        for c in _dates
            push!(dates, c)
        end
        for (k, v) in _srcCtx
            srcCtx[k] = v
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

    # Get the DataAttributeContext
    local dates, values, srcCtx, mini, maxi, titles = analyze(
        widget,
        PlotContext(today = today, store = globalDataStore, maxDate = to, minDate = from),
    )

    # aggregate the context
    local aggregatedCtx = Dict{Tuple{String,String},Array{String,1}}()
    for (k, v) in srcCtx
        for w in v.ctx
            if !((w[1], w[2]) in keys(aggregatedCtx))
                aggregatedCtx[(w[1], w[2])] = []
            end
            push!(aggregatedCtx[(w[1], w[2])], w[3])
        end
    end

    # multiply the context
    local dataAttrCtxs = Array{DataAttributeContext,1}()
    for (k, v) in aggregatedCtx
        local nDataAttrCtxs = Array{DataAttributeContext,1}()
        for w in v
            if length(dataAttrCtxs) == 0
                push!(nDataAttrCtxs, DataAttributeContext(Set([(k..., w)])))
            else
                for c in dataAttrCtxs
                    local cc = copy(c)
                    push!(cc.ctx, (k..., w))
                    push!(nDataAttrCtxs, cc)
                end
            end
        end
        dataAttrCtxs = nDataAttrCtxs
    end

    local results = []

    # Iterate all elements of the product
    for dataAttrCtx in dataAttrCtxs

        local ctxString = ""
        local description = ""
        # Generate Description from Specialization Context!
        for v in dataAttrCtx.ctx
            ctxString *= "$(v[1])($(v[2])) = $(v[3]) "
            local desc = ""
            if (v[1], v[2]) in keys(globalDataStore.descriptions)
                desc = globalDataStore.descriptions[(v[1], v[2])]
            end
            description *= "<b>$(v[1])($(v[2])) = $(v[3])</b><span><i>$desc</i></span><br>\n"
        end
        description = strip(description)
        ctxString = strip(ctxString)        
        local title = "$(widget.title) $ctxString"

        logger(title, "Plotting with context", true)

        local ctx = PlotContext(
            palette = palette,
            today = today,
            store = globalDataStore,
            maxDate = to,
            minDate = from,
        )

        # init the plot
        ctx.plot = plot(
            left_margin = 5mm,
            title = title,
            size = size,
            legend = :topleft,
            yformatter = Y_FORMATTER,
        )
        ctx.styles["source context"] = dataAttrCtx
        local dates, values, srcCtx, mini, maxi, titles = analyze(widget, ctx)

        if DRAW_NIGHT_BACKGROUND
            addBackground!(dates, ctx)
            # vspan overwrites the default format. Restore it.
            plot!(ctx.plot, yformatter = Y_FORMATTER)
        end

        for el in widget.data
            ctx.styles = defaultStyles()
            ctx.styles["source context"] = dataAttrCtx
            renderWidget!(el, ctx)
        end

        local points = getPoints(globalDataStore, from, to)

        addPoints!(points, ctx)
        addTicks!(dates, ctx)
        plot!(ctx.plot, yformatter = Y_FORMATTER)

        # save to plot
        mkpath(saveTo)
        local path = joinpath(saveTo, "$(sanitizeFile(title)).png")
        savefig(ctx.plot, path)

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

        push!(results, (path, titles, title, description))
    end

    return results
end


