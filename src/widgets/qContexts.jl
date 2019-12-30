include("base.jl")
using Dates

function analyze(widget::QContext, ctx::PlotContext)
    local dates, srcCtx, mini, maxi, titles = analyze(widget.data, ctx)

    return dates, srcCtx, mini, maxi, titles
end

function renderWidget!(widget::QContext, ctx::PlotContext)
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

