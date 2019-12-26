import Dates
using Dates

include(joinpath(@__DIR__, "util.jl"))
include(joinpath(@__DIR__, "..", "conf.jl"))
include(joinpath(@__DIR__, "data.jl"))

println("Loading Plots...")


@time begin
    using Plots
    using PlotThemes
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
end
PlotContext(;
    plot = nothing,
    palette = nothing,
    styles::Dict{String,Any} = defaultStyles(),
    today::DateTime = Dates.now(),
    store::DataStore = DataStore(),
    maxDate::DateTime = Dates.now(),
    minDate::DateTime = Dates.now(),
) = PlotContext(plot, palette, styles, today, store, maxDate, minDate)


function analyze(widget::QStack, ctx::PlotContext)
    local dates = Array{DateTime,1}()
    local values = nothing
    local srcCtx = Array{String,1}()
    local points = Set{Tuple{DateTime,String}}()

    for attr in widget.stacked
        local _dates, _values, _srcCtx, _points = analyze(attr, ctx)

        # TODO: What about stacking lines with different resolution?
        # One would have to interpolate values and sort the dates...

        @assert length(_dates) == length(_values)
        #@assert length(dates) == length(_dates) "$(length(dates)) == $(length(_dates))"
        dates = _dates
        for c in _srcCtx
            push!(srcCtx, c)
        end
        for p in _points
            push!(points, p)
        end
        if values === nothing
            values = _values
        else
            @assert length(values) == length(_values)
            values += _values
        end
    end

    return dates, values, srcCtx, points
end

function renderWidget!(widget::QStack, ctx::PlotContext)

    local myStyle = copy(ctx.styles)
    local i = 1
    local dates = nothing
    local values = nothing
    local accum = 0.0

    for attr in widget.stacked
        ctx.styles = myStyle
        ctx.styles["fillrange"] = accum
        ctx.styles["offset"] = accum
        dates, values = renderWidget!(attr, ctx)
        accum = values
    end

    return dates, accum
end


function analyze(widget::QGroup, ctx::PlotContext)
    # TODO
end

function renderWidget!(widget::QGroup, ctx::PlotContext)
    # TODO
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
    local points = []

    return dates, values, srcCtx, points
end

import Base.+
+(arr::Array{Any,1}, b::Number) = begin
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
    if typeof(ctx.styles["fillrange"]) <: Array
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

    values += ctx.styles["offset"]

    # add to graph
    plot!(
        ctx.plot,
        dates,
        values,
        label = label,
        color = color,
        fillrange = ctx.styles["fillrange"],
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

function addPoints!(points::Set{Tuple{DateTime,String}}, ctx::PlotContext)
    # group points by label
    local pointClasses = Dict{String,Array{DateTime,1}}()
    for point in points
        local v = point[1]
        if point[2] ∉ keys(pointClasses)
            pointClasses[point[2]] = [v]
        else
            push!(pointClasses[point[2]], v)
        end
    end

    # plot points
    for (label, ps) in pointClasses
        scatter!(ctx.plot, ps, [0 for _ in 1:length(ps)], label = label)
    end
end

global dataStore = DataStore()

function analyze(widget::QPlot, ctx::PlotContext)
    local dates = Set{DateTime}()
    local srcCtx = Array{String,1}()
    local points = Set{Tuple{DateTime,String}}()

    for attr in widget.data
        local _dates, _values, _srcCtx, _points = analyze(attr, ctx)

        @assert length(_dates) == length(_values)
        for c in _dates
            push!(dates, c)
        end
        for c in _srcCtx
            push!(srcCtx, c)
        end
        for p in _points
            push!(points, p)
        end
    end

    return sort(collect(dates)), nothing, srcCtx, points
end

function renderWidget(widget::QPlot, today::DateTime, saveTo::String)
    logger("", "Plotting $(widget.title)", true)

    local size = widget.size
    if size === nothing
        size = DEFAULT_SIZE
    end
    local palette = loadPalette(PLOT_THEME)

    # init the plot
    local p = plot(title = widget.title, size = size, legend = :topleft)
    local ctx = PlotContext(
        plot = p,
        palette = palette,
        today = today,
        store = dataStore,
        maxDate = today,
        minDate = today - Dates.Day(3),
    )

    local dates, values, srcCtx, points = analyze(widget, ctx)

    addBackground!(dates, ctx)

    for el in widget.data
        ctx.styles = defaultStyles()
        renderWidget!(el, ctx)
    end

    addPoints!(points, ctx)
    addTicks!(dates, ctx)

    # save to plot
    mkpath(saveTo)
    local path = joinpath(saveTo, "$(sanitizeFile(widget.title)).png")
    savefig(ctx.plot, path)
    return path
end