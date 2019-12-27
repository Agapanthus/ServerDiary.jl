import Dates
using Dates

include(joinpath(@__DIR__, "util.jl"))
include(joinpath(@__DIR__, "..", "conf.jl"))
include(joinpath(@__DIR__, "data.jl"))

println("Loading Plots...")

using Formatting
global Y_FORMATTER = yi -> replace(format(yi, commas = true), "," => " ")

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


mutable struct Palette
    palette
    index
end

function loadPalette(theme)::Palette
    local palette = PlotThemes.palette(theme) # get_color_palette(:auto, plot_color(:white), 17)
    return Palette(palette, 1)
end

function nextColor!(p::Palette)
    p.index = (p.index + 1) % length(p.palette) + 1
    return p.palette[p.index]
end


function defaultStyles()::Dict{String,Any}
    return Dict{String,Any}(
        "color" => nothing,
        "fillcolor" => nothing,
        "fillalpha" => 0.2,
        "fillrange" => nothing,
        "offset" => 0.0,
    )
end

mutable struct PlotContext
    plot
    palette::Palette
    styles::Dict{String,Any}
    today::DateTime
    store::DataStore
    maxDate::DateTime
    minDate::DateTime
    group::Int
end
PlotContext(;
    plot = nothing,
    palette = nothing,
    styles::Dict{String,Any} = defaultStyles(),
    today::DateTime = Dates.now(),
    store::DataStore = DataStore(),
    maxDate::DateTime = Dates.now(),
    minDate::DateTime = Dates.now(),
    group::Int = 0
) = PlotContext(plot, palette, styles, today, store, maxDate, minDate, group)


############################

include(joinpath(@__DIR__, "QStack.jl"))
# TODO: everything in seperate files and as modules!


function analyze(widget::QGroup, ctx::PlotContext)
    local dates = Array{DateTime,1}()
    local values = nothing
    local srcCtx = Array{String,1}()
    local mini = typemax(Float64)
    local maxi = typemin(Float64)
    local titles = Array{String,1}()

    for attr in widget.data
        local _dates, _values, _srcCtx, _mini, _maxi, _titles = analyze(attr, ctx)

        @assert length(_dates) == length(_values)
        dates = _dates
        for c in _srcCtx
            push!(srcCtx, c)
        end
        if values === nothing
            values = _values
        end
        mini = min(mini, minimum(values), _mini)
        maxi = max(maxi, maximum(values), _maxi)
        titles = [titles..., _titles...]
    end

    return dates, values, srcCtx, mini, maxi, titles
end

function renderWidget!(widget::QGroup, ctx::PlotContext)
    # Check if this group is a specialication
    local dates, values, srcCtx, mini, maxi, titles = analyze(widget, ctx)

    local oPlot = ctx.plot
    local myStyle = ctx.styles
    ctx.group += 1

    if ctx.group == 2
        plot!(oPlot, right_margin = 25mm) # increase margin in parent
        ctx.plot = twinx(ctx.plot)
        plot!(ctx.plot, y_formatter = Y_FORMATTER) # set formatter in child
    end
    plot!(ctx.plot, ylabel = widget.unit)
    if widget.log
        plot!(ctx.plot, yaxis = :log)
    end

    @assert ctx.group <= 2 "Currently only two groups are supported"
    local yMax = maxi
    local yMin = mini
    if widget.min !== nothing
        yMin = widget.min
    end
    if widget.log
        @assert widget.min === nothing || widget.min > 0
        if yMin <= 0
            yMin = 1
        end
        ctx.styles["log"] = yMin
    else
        yMin = min(yMin, 0)
    end

    if widget.max !== nothing
        yMax = widget.max
    end

    for w in widget.data
        ctx.styles = deepcopy(myStyle)
        ctx.styles["ylims"] = (yMin, yMax)
        renderWidget!(w, ctx)
    end

    ctx.plot = oPlot

    return dates, values
end


function analyze(widget::QStyled, ctx::PlotContext)
    return analyze(widget.data, ctx)
end


function renderWidget!(widget::QStyled, ctx::PlotContext)
    for (k, v) in widget.overloads
        ctx.styles[k] = v
    end
    return renderWidget!(widget.data, ctx)
end

function analyze(attr::DataAttribute, ctx::PlotContext)
    local dates, values = fetchData!(ctx.store, attr, ctx.minDate, ctx.maxDate)
    # TODO: Multiply along text columns!
    local srcCtx = []

    return dates, values, srcCtx, minimum(values), maximum(values), [attr.property]
end

import Base.+
+(arr::Array{<:Number,1}, b::Number) = begin
    arr = copy(arr)
    if b == 0
        return arr
    end
    for i in 1:length(arr)
        arr[i] += b
    end
    return arr
end


function renderWidget!(attr::DataAttribute, ctx::PlotContext)

    local dates, values, srcCtx, _ = analyze(attr, ctx)
    @assert length(srcCtx) == 0 "Ambiguos attribute."

    local label = attr.property
    if "stacked" in keys(ctx.styles)
        label *= " (stacked)"
    end

    local color = ctx.styles["color"]
    local fcolor = ctx.styles["fillcolor"]
    if ctx.styles["color"] === nothing
        color = nextColor!(ctx.palette)
    end
    if fcolor === nothing
        fcolor = color
    end

    # For example in stacked plots we need some offset
    values += ctx.styles["offset"]

    local fillrange = ctx.styles["fillrange"]
    # Filling a log plot is tricky! Don't go below the minimum!
    if "log" in keys(ctx.styles)
        local l = ctx.styles["log"]
        if typeof(fillrange) <: Array
            fillrange = map(x -> max(x, l), fillrange)
        elseif typeof(fillrange) <: Number
            fillrange = max(fillrange, l)
        end
    end

    local ylims = nothing
    if "ylims" in keys(ctx.styles)
        ylims = ctx.styles["ylims"]
    end

    # add to graph
    plot!(
        ctx.plot,
        dates,
        values,
        label = label,
        color = color,
        ylims = ylims,
        fillrange = fillrange,
        fillcolor = fcolor,
        fillalpha = ctx.styles["fillalpha"],
    )

    return dates, values
end


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
        @show label ps 
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

    # save to plot
    mkpath(saveTo)
    local path = joinpath(saveTo, "$(sanitizeFile(widget.title)).png")
    savefig(ctx.plot, path)
    return path
end



renderWidget(QUERY[1], Dates.now(), joinpath(BASE_PATH, "stats"))
